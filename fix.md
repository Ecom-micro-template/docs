# Architecture & Code Improvement Plan: E-commerce Platform

## Executive Summary

This plan addresses **critical data consistency and concurrency risks** identified in the microservices architecture. The improvements are designed for **incremental deployment** and leverage both existing infrastructure (PostgreSQL, Redis, NATS) and potentially new tools (Temporal for saga orchestration).

---

## Critical Risks Identified

| Risk | Severity | Current State | Impact |
|------|----------|---------------|--------|
| Payment + Order not atomic | **CRITICAL** | Two separate DB updates | Paid orders not confirmed |
| No Outbox pattern | **HIGH** | NATS publish can fail | Lost events, inconsistent state |
| No optimistic locking | **HIGH** | Only pessimistic locks | Cannot detect concurrent edits |
| Dual stock tables | **HIGH** | `inventory.stock_items` vs `public.warehouse_stock` | Stock divergence |
| No distributed locks | **MEDIUM** | Redis used only for cache | Cache-DB race conditions |
| Uncontrolled goroutines | **MEDIUM** | No shutdown mechanisms | Memory leaks on restart |

---

## Phase 1: Critical Fixes (Immediate)

### 1.1 Payment-Order Atomicity

**Problem:** [payment_service.go:592-601](service-order/internal/services/payment_service.go#L592-L601)
```go
// Current: Two separate updates - NOT ATOMIC
if err := s.paymentRepo.UpdatePayment(payment); err != nil { ... }
if err := s.orderRepo.UpdateOrder(order); err != nil { ... }
```

**Solution:** Wrap in single transaction

**File to modify:** `service-order/internal/services/payment_service.go`

```go
// Fix: Single transaction
func (s *PaymentService) VerifyCurlecPayment(...) (*PaymentResult, error) {
    // ... verification logic ...

    return s.db.Transaction(func(tx *gorm.DB) error {
        payment.Status = models.PaymentStatusCompleted
        // ... set payment fields ...

        if err := tx.Save(payment).Error; err != nil {
            return fmt.Errorf("update payment: %w", err)
        }

        order.Status = models.OrderStatusConfirmed
        order.PaymentStatus = "paid"
        if err := tx.Save(order).Error; err != nil {
            return fmt.Errorf("update order: %w", err)a
        }

        return nil
    })
}
```

---

### 1.2 Add Optimistic Locking to Critical Models

**Problem:** [stock_item.go](service-inventory/internal/models/stock_item.go) - No version field

**Solution:** Add version field for optimistic locking

**Files to modify:**
- `service-inventory/internal/models/stock_item.go`
- `service-order/internal/models/order.go`
- `service-catalog/internal/models/product.go`

```go
type StockItem struct {
    // ... existing fields ...
    Version   int64     `gorm:"column:version;default:1" json:"version"`
    UpdatedAt time.Time `json:"updated_at"`
}

// BeforeUpdate hook for optimistic locking
func (s *StockItem) BeforeUpdate(tx *gorm.DB) error {
    tx.Statement.Where("version = ?", s.Version)
    s.Version++
    return nil
}
```

**Migration SQL:**
```sql
ALTER TABLE inventory.stock_items ADD COLUMN version BIGINT DEFAULT 1;
ALTER TABLE orders.orders ADD COLUMN version BIGINT DEFAULT 1;
ALTER TABLE catalog.products ADD COLUMN version BIGINT DEFAULT 1;
```

---

### 1.3 Graceful Goroutine Shutdown

**Problem:** [idempotency.go:24](service-inventory/internal/events/idempotency.go#L24) - Goroutine never stops

**Solution:** Add context-based cancellation

**Files to modify:**
- `service-inventory/internal/events/idempotency.go`
- `lib-common/middleware/ratelimit.go`

```go
type IdempotencyChecker struct {
    processed map[string]time.Time
    mu        sync.RWMutex
    ttl       time.Duration
    done      chan struct{}  // Add shutdown channel
}

func NewIdempotencyChecker(ttl time.Duration) *IdempotencyChecker {
    ic := &IdempotencyChecker{
        processed: make(map[string]time.Time),
        ttl:       ttl,
        done:      make(chan struct{}),
    }
    go ic.cleanupLoop()
    return ic
}

func (ic *IdempotencyChecker) cleanupLoop() {
    ticker := time.NewTicker(ic.ttl / 2)
    defer ticker.Stop()
    for {
        select {
        case <-ticker.C:
            ic.cleanup()
        case <-ic.done:
            return  // Graceful exit
        }
    }
}

func (ic *IdempotencyChecker) Shutdown() {
    close(ic.done)
}
```

---

## Phase 2: Data Consistency Patterns

### 2.1 Implement Outbox Pattern for Events

**Problem:** NATS publish not transactional with DB operations

**Solution:** Store events in outbox table, process asynchronously

**New files:**
- `lib-common/outbox/outbox.go`
- `lib-common/outbox/processor.go`

**Migration SQL:**
```sql
CREATE TABLE outbox.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    error TEXT,
    retry_count INT DEFAULT 0
);

CREATE INDEX idx_outbox_unprocessed ON outbox.events(created_at)
WHERE processed_at IS NULL;
```

**Outbox implementation:**
```go
package outbox

type Event struct {
    ID            uuid.UUID       `gorm:"type:uuid;primary_key"`
    AggregateType string          `gorm:"type:varchar(100)"`
    AggregateID   uuid.UUID       `gorm:"type:uuid"`
    EventType     string          `gorm:"type:varchar(100)"`
    Payload       datatypes.JSON  `gorm:"type:jsonb"`
    CreatedAt     time.Time
    ProcessedAt   *time.Time
    Error         *string
    RetryCount    int
}

type Outbox struct {
    db *gorm.DB
}

// PublishInTransaction saves event in same transaction as business logic
func (o *Outbox) PublishInTransaction(tx *gorm.DB, event *Event) error {
    return tx.Create(event).Error
}
```

**Usage in order service:**
```go
func (s *OrderService) CreateOrder(...) error {
    return s.db.Transaction(func(tx *gorm.DB) error {
        // 1. Create order
        if err := tx.Create(order).Error; err != nil {
            return err
        }

        // 2. Reserve stock
        if err := s.reserveStock(tx, order); err != nil {
            return err
        }

        // 3. Add event to outbox (same transaction!)
        event := &outbox.Event{
            AggregateType: "order",
            AggregateID:   order.ID,
            EventType:     "order.created",
            Payload:       toJSON(order),
        }
        return s.outbox.PublishInTransaction(tx, event)
    })
}
```

---

### 2.2 Implement Saga Pattern for Order Flow

**Problem:** Multi-step order flow lacks coordination

**Solution:** Implement choreography-based saga with compensation

**New file:** `service-order/internal/saga/order_saga.go`

```go
package saga

type OrderSaga struct {
    orderRepo      OrderRepository
    stockService   StockService
    paymentService PaymentService
    catalogClient  CatalogClient
    outbox         *outbox.Outbox
    logger         *zap.Logger
}

type SagaStep struct {
    Name       string
    Execute    func(ctx context.Context) error
    Compensate func(ctx context.Context) error
}

func (s *OrderSaga) CreateOrder(ctx context.Context, req CreateOrderRequest) (*Order, error) {
    var order *Order
    var reservation *StockReservation
    var flashSaleReserved bool

    steps := []SagaStep{
        {
            Name: "create_order",
            Execute: func(ctx context.Context) error {
                var err error
                order, err = s.orderRepo.Create(req)
                return err
            },
            Compensate: func(ctx context.Context) error {
                return s.orderRepo.Delete(order.ID)
            },
        },
        {
            Name: "reserve_stock",
            Execute: func(ctx context.Context) error {
                var err error
                reservation, err = s.stockService.Reserve(order)
                return err
            },
            Compensate: func(ctx context.Context) error {
                return s.stockService.Release(reservation)
            },
        },
        {
            Name: "reserve_flash_sale",
            Execute: func(ctx context.Context) error {
                if !req.HasFlashSaleItems() {
                    return nil
                }
                flashSaleReserved = true
                return s.catalogClient.ReserveFlashSale(order)
            },
            Compensate: func(ctx context.Context) error {
                if !flashSaleReserved {
                    return nil
                }
                return s.catalogClient.CancelFlashSaleReservation(order)
            },
        },
    }

    // Execute saga with automatic compensation on failure
    if err := s.executeSaga(ctx, steps); err != nil {
        return nil, err
    }

    return order, nil
}

func (s *OrderSaga) executeSaga(ctx context.Context, steps []SagaStep) error {
    completed := make([]SagaStep, 0, len(steps))

    for _, step := range steps {
        if err := step.Execute(ctx); err != nil {
            s.logger.Error("Saga step failed, compensating",
                zap.String("step", step.Name),
                zap.Error(err))

            // Compensate in reverse order
            for i := len(completed) - 1; i >= 0; i-- {
                if compErr := completed[i].Compensate(ctx); compErr != nil {
                    s.logger.Error("Compensation failed",
                        zap.String("step", completed[i].Name),
                        zap.Error(compErr))
                    // Log for manual intervention
                }
            }
            return fmt.Errorf("saga failed at %s: %w", step.Name, err)
        }
        completed = append(completed, step)
    }

    return nil
}
```

---

### 2.3 Add Idempotency Keys to Payment Operations

**Problem:** Payment retries could create duplicate charges

**Solution:** Add idempotency key support

**File to modify:** `service-order/internal/services/payment_service.go`

```go
type PaymentRequest struct {
    OrderID        uuid.UUID `json:"order_id"`
    IdempotencyKey string    `json:"idempotency_key"` // Add this
    // ... other fields
}

func (s *PaymentService) InitiatePayment(req *PaymentRequest) (*PaymentResult, error) {
    // Check for existing payment with same idempotency key
    existing, err := s.paymentRepo.FindByIdempotencyKey(req.IdempotencyKey)
    if err == nil && existing != nil {
        // Return existing result (idempotent)
        return s.buildResultFromExisting(existing), nil
    }

    // Create new payment with idempotency key
    payment := &Payment{
        IdempotencyKey: req.IdempotencyKey,
        // ... other fields
    }
    // ... proceed with payment
}
```

**Migration SQL:**
```sql
ALTER TABLE orders.payments ADD COLUMN idempotency_key VARCHAR(64);
CREATE UNIQUE INDEX idx_payments_idempotency ON orders.payments(idempotency_key)
WHERE idempotency_key IS NOT NULL;
```

---

## Phase 3: Concurrency Safety

### 3.1 Implement Distributed Locks with Redis

**Problem:** No distributed locking for cross-service operations

**New file:** `lib-common/lock/redis_lock.go`

```go
package lock

import (
    "context"
    "errors"
    "time"

    "github.com/redis/go-redis/v9"
)

var ErrLockNotAcquired = errors.New("lock not acquired")

type RedisLock struct {
    client *redis.Client
    key    string
    value  string
    ttl    time.Duration
}

func NewRedisLock(client *redis.Client, key string, ttl time.Duration) *RedisLock {
    return &RedisLock{
        client: client,
        key:    "lock:" + key,
        value:  uuid.New().String(),
        ttl:    ttl,
    }
}

// Acquire attempts to acquire the lock with retry
func (l *RedisLock) Acquire(ctx context.Context) error {
    for i := 0; i < 10; i++ {
        ok, err := l.client.SetNX(ctx, l.key, l.value, l.ttl).Result()
        if err != nil {
            return fmt.Errorf("redis error: %w", err)
        }
        if ok {
            return nil // Lock acquired
        }

        // Wait before retry
        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-time.After(50 * time.Millisecond):
        }
    }
    return ErrLockNotAcquired
}

// Release releases the lock (only if we own it)
func (l *RedisLock) Release(ctx context.Context) error {
    script := `
        if redis.call("get", KEYS[1]) == ARGV[1] then
            return redis.call("del", KEYS[1])
        else
            return 0
        end
    `
    _, err := l.client.Eval(ctx, script, []string{l.key}, l.value).Result()
    return err
}

// WithLock executes function while holding lock
func WithLock(ctx context.Context, client *redis.Client, key string, ttl time.Duration, fn func() error) error {
    lock := NewRedisLock(client, key, ttl)
    if err := lock.Acquire(ctx); err != nil {
        return err
    }
    defer lock.Release(ctx)
    return fn()
}
```

**Usage in stock reservation:**
```go
func (s *StockService) ReserveStock(productID uuid.UUID, qty int) error {
    lockKey := fmt.Sprintf("stock:%s", productID)

    return lock.WithLock(ctx, s.redis, lockKey, 10*time.Second, func() error {
        // Now safe to read-modify-write
        stock, err := s.repo.GetStock(productID)
        if err != nil {
            return err
        }

        if stock.Available < qty {
            return ErrInsufficientStock
        }

        stock.Reserved += qty
        return s.repo.Update(stock)
    })
}
```

---

### 3.2 Unify Stock Tables

**Problem:** `inventory.stock_items` (inventory service) vs `public.warehouse_stock` (order service)

**Solution:** Single source of truth with API calls

**Files to modify:**
- `service-order/internal/services/stock_reservation.go` - Remove direct DB access
- Add stock reservation API to `service-inventory`

**New endpoint in service-inventory:**
```go
// POST /api/v1/internal/stock/reserve
type ReserveStockRequest struct {
    ProductID   uuid.UUID `json:"product_id"`
    VariantID   *uuid.UUID `json:"variant_id"`
    WarehouseID uuid.UUID `json:"warehouse_id"`
    Quantity    int       `json:"quantity"`
    OrderID     uuid.UUID `json:"order_id"`
    TTL         int       `json:"ttl_seconds"` // Reservation expiry
}
```

**Order service calls inventory service:**
```go
// In service-order/internal/clients/inventory_client.go
type InventoryClient struct {
    baseURL    string
    httpClient *http.Client
}

func (c *InventoryClient) ReserveStock(ctx context.Context, req *ReserveStockRequest) error {
    // HTTP call to inventory service
    resp, err := c.httpClient.Post(c.baseURL+"/api/v1/internal/stock/reserve", ...)
    // Handle response
}
```

---

### 3.3 Cache Invalidation with Read-Through Pattern

**Problem:** Cache-DB inconsistency during updates

**Solution:** Write-through + event-based invalidation

**File to modify:** `service-inventory/internal/cache/redis.go`

```go
type CacheService struct {
    redis  *redis.Client
    repo   *StockRepository
    logger *zap.Logger
}

// GetStockWithCache implements read-through caching
func (c *CacheService) GetStockWithCache(ctx context.Context, productID uuid.UUID) (*StockAvailability, error) {
    key := fmt.Sprintf("stock:%s", productID)

    // Try cache first
    cached, err := c.redis.Get(ctx, key).Bytes()
    if err == nil {
        var stock StockAvailability
        if json.Unmarshal(cached, &stock) == nil {
            return &stock, nil
        }
    }

    // Cache miss - fetch from DB
    stock, err := c.repo.GetAvailability(productID)
    if err != nil {
        return nil, err
    }

    // Write to cache
    data, _ := json.Marshal(stock)
    c.redis.Set(ctx, key, data, 5*time.Minute)

    return stock, nil
}

// InvalidateOnUpdate invalidates cache after DB update
func (c *CacheService) InvalidateOnUpdate(ctx context.Context, productID uuid.UUID) {
    key := fmt.Sprintf("stock:%s", productID)
    c.redis.Del(ctx, key)
}
```

---

## Phase 4: Optional - Temporal for Complex Sagas

If you want more robust saga orchestration, consider adding **Temporal** workflow engine.

**Benefits:**
- Automatic retries with backoff
- Built-in compensation handling
- Visibility into running workflows
- Durable execution (survives crashes)

**New files:**
- `service-order/internal/workflows/order_workflow.go`
- `service-order/internal/activities/order_activities.go`

This is optional and can be implemented later when complexity increases.

---

## Implementation Order

```
Phase 1 (Week 1-2): Critical Fixes
├── 1.1 Payment-Order atomicity
├── 1.2 Add version fields + migrations
└── 1.3 Graceful goroutine shutdown

Phase 2 (Week 3-4): Data Consistency
├── 2.1 Outbox pattern + processor
├── 2.2 Saga pattern for orders
└── 2.3 Idempotency keys

Phase 3 (Week 5-6): Concurrency Safety
├── 3.1 Redis distributed locks
├── 3.2 Unify stock tables (inventory API)
└── 3.3 Cache invalidation improvements

Phase 4 (Future): Optional Enhancements
└── Temporal workflow engine
```

---

## Files to Modify Summary

| Priority | File | Change |
|----------|------|--------|
| P0 | `service-order/internal/services/payment_service.go` | Wrap payment+order in transaction |
| P0 | `service-inventory/internal/models/stock_item.go` | Add version field |
| P0 | `service-inventory/internal/events/idempotency.go` | Add shutdown channel |
| P1 | `lib-common/outbox/outbox.go` | New file - outbox pattern |
| P1 | `service-order/internal/saga/order_saga.go` | New file - saga orchestration |
| P1 | `service-order/internal/services/payment_service.go` | Add idempotency key |
| P2 | `lib-common/lock/redis_lock.go` | New file - distributed locks |
| P2 | `service-order/internal/services/stock_reservation.go` | Use inventory API instead of direct DB |
| P2 | `service-inventory/internal/cache/redis.go` | Add write-through pattern |
| P2 | `lib-common/middleware/ratelimit.go` | Add shutdown mechanism |

---

## Database Migrations Required

```sql
-- Phase 1: Version fields
ALTER TABLE inventory.stock_items ADD COLUMN version BIGINT DEFAULT 1;
ALTER TABLE orders.orders ADD COLUMN version BIGINT DEFAULT 1;
ALTER TABLE catalog.products ADD COLUMN version BIGINT DEFAULT 1;

-- Phase 2: Outbox table
CREATE SCHEMA IF NOT EXISTS outbox;
CREATE TABLE outbox.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(100) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    processed_at TIMESTAMPTZ,
    error TEXT,
    retry_count INT DEFAULT 0
);
CREATE INDEX idx_outbox_unprocessed ON outbox.events(created_at) WHERE processed_at IS NULL;

-- Phase 2: Idempotency key
ALTER TABLE orders.payments ADD COLUMN idempotency_key VARCHAR(64);
CREATE UNIQUE INDEX idx_payments_idempotency ON orders.payments(idempotency_key) WHERE idempotency_key IS NOT NULL;
```

---

## Testing Strategy

1. **Unit tests** for new saga and outbox code
2. **Integration tests** for distributed lock behavior
3. **Chaos testing** - kill services mid-transaction to verify compensation
4. **Load testing** - concurrent orders during flash sale simulation
