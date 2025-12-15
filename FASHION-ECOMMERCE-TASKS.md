# Fashion eCommerce Platform - Implementation Tasks

> Gap Analysis & Task List for Kilang Desa Murni Batik
>
> Generated: 2024-12-15 | Based on: FASHION-ECOMMERCE-ARCHITECTURE.md

---

## Executive Summary

This document identifies the gaps between the **current implementation** and the **target Fashion eCommerce architecture**. Tasks are organized by service and priority.

### Overall Status

| Service | Implemented | Partial | Missing | Completion |
|---------|-------------|---------|---------|------------|
| service-catalog | 12 | 2 | 4 | ~70% |
| service-inventory | 8 | 0 | 0 | ~95% |
| service-customer | 5 | 1 | 4 | ~55% |
| service-order | 5 | 1 | 2 | ~70% |
| frontend-storefront | - | - | - | ~50% |
| frontend-admin | - | - | - | ~60% |

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Fully Implemented |
| ⚠️ | Partially Implemented |
| ❌ | Not Implemented |
| 🔥 | High Priority |
| 📦 | Medium Priority |
| 🧊 | Low Priority |

---

## 1. SERVICE-CATALOG Tasks

### Current State
- ✅ Products with variants/SKUs
- ✅ Categories with hierarchy
- ✅ Featured Collections (basic)
- ✅ Comprehensive Discount Engine (4 types)
- ✅ Batik-specific fields (fabric, tailoring)
- ✅ Colors, Size Charts, Fabric Designs
- ✅ CMS (banners, promo boxes, announcements)
- ✅ Product images with MinIO

### Tasks to Implement

#### 🔥 HIGH PRIORITY

| ID | Task | Description | Effort | Status |
|----|------|-------------|--------|--------|
| CAT-001 | **Flash Sale Engine** | Add dedicated flash sale model with: time limits, stock limits per SKU, purchase limits per customer, countdown support | 3-5 days | ✅ DONE |
| CAT-002 | **Auto-Collections** | Rules-based collections (e.g., "New in 30 days", "Price < RM100", "Category = Silk") | 2-3 days | ❌ |
| CAT-003 | **Variant Availability API** | Single endpoint returning full Size×Color matrix with stock status for PDP | 1-2 days | ❌ |
| CAT-004 | **Shop the Look** | Model for grouping products as coordinated outfits (baju + sampin + songkok) | 2-3 days | ❌ |

#### 📦 MEDIUM PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| CAT-005 | **Lookbook System** | Editorial-style product presentations with images, descriptions, linked products | 2-3 days |
| CAT-006 | **Product Bundles** | Bundle multiple products with special pricing (different from BXGY discount) | 2-3 days |
| CAT-007 | **Related Products** | "Customers also bought", "Similar patterns" recommendations | 2-3 days |
| CAT-008 | **Trending Products** | Track view counts, purchases to surface trending items | 1-2 days |

#### 🧊 LOW PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| CAT-009 | **Visual Search** | Image-based product discovery (requires ML service) | 5+ days |
| CAT-010 | **Fabric Calculator** | For "kain" products: meters needed for baju kurung, baju melayu, etc. | 1-2 days |

---

### CAT-001: Flash Sale Engine - Detailed Spec

```sql
-- New tables needed
CREATE TABLE flash_sales (
    id              UUID PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) UNIQUE,
    description     TEXT,
    banner_image    VARCHAR(500),

    -- Timing (critical for flash sales)
    start_time      TIMESTAMP NOT NULL,
    end_time        TIMESTAMP NOT NULL,

    -- Discount
    discount_type   VARCHAR(20) NOT NULL,  -- 'percentage', 'fixed'
    discount_value  DECIMAL(10,2) NOT NULL,

    -- Limits
    max_per_customer INTEGER DEFAULT 2,

    -- Display
    show_countdown  BOOLEAN DEFAULT TRUE,
    show_stock_remaining BOOLEAN DEFAULT TRUE,

    -- Status
    status          VARCHAR(20) DEFAULT 'scheduled',

    created_at      TIMESTAMP DEFAULT NOW(),
    created_by      UUID
);

CREATE TABLE flash_sale_items (
    flash_sale_id   UUID REFERENCES flash_sales(id),
    variant_id      UUID NOT NULL,  -- Links to product_variants

    original_price  DECIMAL(10,2) NOT NULL,
    flash_price     DECIMAL(10,2) NOT NULL,
    stock_limit     INTEGER NOT NULL,
    sold_count      INTEGER DEFAULT 0,

    PRIMARY KEY (flash_sale_id, variant_id)
);

CREATE TABLE flash_sale_purchases (
    id              UUID PRIMARY KEY,
    flash_sale_id   UUID REFERENCES flash_sales(id),
    customer_id     UUID NOT NULL,
    variant_id      UUID NOT NULL,
    quantity        INTEGER NOT NULL,
    purchased_at    TIMESTAMP DEFAULT NOW(),

    -- For enforcing per-customer limits
    UNIQUE(flash_sale_id, customer_id, variant_id)
);
```

**API Endpoints Needed:**
```
# Admin
POST   /api/v1/admin/flash-sales              # Create flash sale
GET    /api/v1/admin/flash-sales              # List flash sales
GET    /api/v1/admin/flash-sales/:id          # Get flash sale details
PUT    /api/v1/admin/flash-sales/:id          # Update flash sale
DELETE /api/v1/admin/flash-sales/:id          # Delete flash sale
POST   /api/v1/admin/flash-sales/:id/items    # Add items to flash sale
DELETE /api/v1/admin/flash-sales/:id/items/:variantId  # Remove item

# Public
GET    /api/v1/flash-sales/active             # Get active flash sales
GET    /api/v1/flash-sales/:slug              # Get flash sale by slug
GET    /api/v1/flash-sales/:id/availability   # Check remaining stock
```

---

### CAT-003: Variant Availability API - Detailed Spec

**Endpoint:** `GET /api/v1/products/:id/availability`

**Response:**
```json
{
  "product_id": "uuid",
  "product_name": "Batik Silk Sarong",
  "options": [
    {
      "name": "Color",
      "values": [
        {"value": "Red", "color_code": "#FF0000"},
        {"value": "Blue", "color_code": "#0000FF"},
        {"value": "Black", "color_code": "#000000"}
      ]
    },
    {
      "name": "Size",
      "values": ["S", "M", "L", "XL"]
    }
  ],
  "variants": [
    {
      "id": "uuid",
      "sku": "BSS-001-R-S",
      "options": {"Color": "Red", "Size": "S"},
      "price": 250.00,
      "compare_price": 300.00,
      "available": 12,
      "status": "in_stock"
    },
    {
      "id": "uuid",
      "sku": "BSS-001-R-M",
      "options": {"Color": "Red", "Size": "M"},
      "price": 250.00,
      "available": 3,
      "status": "low_stock"
    },
    {
      "id": "uuid",
      "sku": "BSS-001-BK-M",
      "options": {"Color": "Black", "Size": "M"},
      "price": 270.00,
      "available": 0,
      "status": "out_of_stock"
    }
  ],
  "matrix": {
    "Red": {"S": 12, "M": 3, "L": 20, "XL": 7},
    "Blue": {"S": 8, "M": 15, "L": 18, "XL": 9},
    "Black": {"S": 0, "M": 0, "L": 0, "XL": 0}
  }
}
```

**Implementation Notes:**
- Call inventory service for stock data
- Cache response in Redis (invalidate on stock change)
- Include flash sale pricing if active

---

## 2. SERVICE-INVENTORY Tasks

### Current State
- ✅ Per-SKU/variant stock tracking
- ✅ Multi-warehouse support (3 types)
- ✅ Stock reservations with row-level locking
- ✅ Low stock alerts (threshold-based)
- ✅ Stock movements (7 types)
- ✅ Stock transfers with approval workflow
- ✅ Intelligent allocation (5 strategies)
- ✅ Availability API with Redis caching
- ✅ Prometheus metrics

### Tasks to Implement

#### 📦 MEDIUM PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| INV-001 | **Flash Sale Stock Lock** | Reserve specific stock for flash sales, separate from order reservations | 1-2 days |
| INV-002 | **Inventory Valuation** | FIFO/LIFO cost tracking for profit calculations | 2-3 days |
| INV-003 | **Restock Notifications** | Event emission when out-of-stock item is restocked | 1 day |
| INV-004 | **Purchase Order Integration** | Track incoming stock from suppliers | 3-5 days |

---

### INV-003: Restock Notifications - Detailed Spec

**NATS Event:**
```json
{
  "event": "inventory.restocked",
  "data": {
    "sku": "BSS-001-R-M",
    "product_id": "uuid",
    "variant_id": "uuid",
    "warehouse_id": "uuid",
    "previous_available": 0,
    "new_available": 25,
    "restocked_at": "2024-12-15T10:30:00Z"
  }
}
```

**Trigger:** When `AdjustStock()` increases available quantity from 0 to > 0

**Consumers:**
- `service-customer` - Check for back-in-stock subscriptions
- `service-notification` - Send emails/SMS to subscribed customers

---

## 3. SERVICE-CUSTOMER Tasks

### Current State
- ✅ Customer profiles (basic info)
- ✅ Addresses (shipping/billing)
- ✅ Customer segments with conditions
- ✅ Body measurements (CustomerMeasurement)
- ✅ Customer notes and activity tracking
- ⚠️ Wishlist (product-level only, NOT variant-specific)

### Tasks to Implement

#### 🔥 HIGH PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| CUS-001 | **Variant-Specific Wishlist** | Update wishlist to store `variant_id` instead of just `product_id` | 1-2 days |
| CUS-002 | **Back-in-Stock Notifications** | Allow customers to subscribe for restock alerts on specific variants | 2-3 days |
| CUS-003 | **Style Preferences** | Store preferred colors, patterns, occasions, fit preferences | 1-2 days |

#### 📦 MEDIUM PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| CUS-004 | **Loyalty Points System** | Points per purchase, tier benefits, points redemption | 3-5 days |
| CUS-005 | **Size History** | Track sizes purchased per brand/category for recommendations | 1-2 days |
| CUS-006 | **Recently Viewed** | Store recently viewed products per customer | 1 day |
| CUS-007 | **Saved Searches** | Save search filters with optional notifications | 2 days |

#### 🧊 LOW PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| CUS-008 | **Size Recommendation Engine** | Based on measurements + purchase history, suggest sizes | 3-5 days |
| CUS-009 | **Customer Reviews** | Product reviews with size/fit feedback | 2-3 days |

---

### CUS-001: Variant-Specific Wishlist - Detailed Spec

**Current Model:**
```go
type WishlistItem struct {
    ID        uuid.UUID
    UserID    uuid.UUID
    ProductID uuid.UUID  // Only product!
    CreatedAt time.Time
}
```

**Updated Model:**
```go
type WishlistItem struct {
    ID        uuid.UUID
    UserID    uuid.UUID
    ProductID uuid.UUID
    VariantID *uuid.UUID  // NEW: Optional variant (null = any variant)

    // Denormalized for display
    VariantSKU   *string
    VariantName  *string  // "Red / Large"

    // For price drop alerts
    PriceAtAdd   float64
    NotifyOnSale bool

    CreatedAt time.Time
}
```

**Migration:**
```sql
ALTER TABLE wishlist_items
ADD COLUMN variant_id UUID,
ADD COLUMN variant_sku VARCHAR(50),
ADD COLUMN variant_name VARCHAR(100),
ADD COLUMN price_at_add DECIMAL(10,2),
ADD COLUMN notify_on_sale BOOLEAN DEFAULT FALSE;

-- Update unique constraint
DROP INDEX IF EXISTS idx_wishlist_user_product;
CREATE UNIQUE INDEX idx_wishlist_user_product_variant
ON wishlist_items(user_id, product_id, COALESCE(variant_id, '00000000-0000-0000-0000-000000000000'));
```

---

### CUS-002: Back-in-Stock Notifications - Detailed Spec

**New Model:**
```go
type StockNotification struct {
    ID         uuid.UUID `gorm:"type:uuid;primaryKey"`
    CustomerID uuid.UUID `gorm:"type:uuid;not null;index"`
    ProductID  uuid.UUID `gorm:"type:uuid;not null"`
    VariantID  uuid.UUID `gorm:"type:uuid;not null;index"`

    // Denormalized for display
    ProductName string
    VariantSKU  string
    VariantName string  // "Red / M"

    // Notification preferences
    NotifyEmail bool `gorm:"default:true"`
    NotifySMS   bool `gorm:"default:false"`

    // Status
    Status     string    `gorm:"default:'pending'"` // pending, notified, cancelled
    NotifiedAt *time.Time

    CreatedAt time.Time
    UpdatedAt time.Time
}
```

**API Endpoints:**
```
# Customer
POST   /api/v1/customer/stock-notifications          # Subscribe to restock
GET    /api/v1/customer/stock-notifications          # List subscriptions
DELETE /api/v1/customer/stock-notifications/:id      # Unsubscribe

# Internal (called by inventory service via NATS)
POST   /api/v1/internal/stock-notifications/trigger  # Trigger notifications for SKU
```

**NATS Consumer:**
```go
// Subscribe to inventory.restocked events
func (s *StockNotificationService) HandleRestockEvent(event InventoryRestockedEvent) {
    // Find all pending notifications for this variant
    notifications := s.repo.FindPendingByVariant(event.VariantID)

    for _, notif := range notifications {
        // Queue notification via service-notification
        s.nats.Publish("notification.send", NotificationRequest{
            Type:       "back_in_stock",
            CustomerID: notif.CustomerID,
            Email:      notif.NotifyEmail,
            SMS:        notif.NotifySMS,
            Data: map[string]interface{}{
                "product_name": notif.ProductName,
                "variant_name": notif.VariantName,
                "product_url":  fmt.Sprintf("/products/%s?variant=%s", notif.ProductID, notif.VariantID),
            },
        })

        // Mark as notified
        s.repo.MarkNotified(notif.ID)
    }
}
```

---

### CUS-003: Style Preferences - Detailed Spec

**New Model:**
```go
type CustomerStyleProfile struct {
    ID         uuid.UUID `gorm:"type:uuid;primaryKey"`
    CustomerID uuid.UUID `gorm:"type:uuid;uniqueIndex;not null"`

    // Fit preferences
    PreferredFit string `gorm:"size:20"` // slim, regular, loose

    // Style preferences (stored as JSON arrays)
    PreferredColors   pq.StringArray `gorm:"type:text[]"`  // ["Blue", "Earth tones"]
    PreferredPatterns pq.StringArray `gorm:"type:text[]"`  // ["Floral", "Geometric"]
    PreferredFabrics  pq.StringArray `gorm:"type:text[]"`  // ["Silk", "Cotton"]

    // Occasions they shop for
    Occasions pq.StringArray `gorm:"type:text[]"` // ["Casual", "Formal", "Wedding", "Office"]

    // Size preferences by category
    SizePreferences JSONB `gorm:"type:jsonb"` // {"tops": "M", "bottoms": "32", "baju_kurung": "L"}

    // Price range preference
    PriceRangeMin *float64
    PriceRangeMax *float64

    CreatedAt time.Time
    UpdatedAt time.Time
}
```

---

## 4. SERVICE-ORDER Tasks

### Current State
- ✅ Cart with items (supports decimal qty for fabric)
- ✅ Order management with status workflow
- ✅ Payment integration (Curlec FPX, Card, Wallet)
- ✅ Fulfillment tracking with carrier info
- ✅ Order timeline and notes
- ✅ Coupon system
- ⚠️ Refunds (basic, via payment service)

### Tasks to Implement

#### 🔥 HIGH PRIORITY

| ID | Task | Description | Effort | Status |
|----|------|-------------|--------|--------|
| ORD-001 | **Self-Service Returns Portal** | Customer-initiated returns with reason selection, status tracking | 3-5 days | ❌ |
| ORD-002 | **Flash Sale Purchase Validation** | Check per-customer limits, flash sale stock before checkout | 1-2 days | ✅ DONE |

#### 📦 MEDIUM PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| ORD-003 | **One-Click Reorder** | Reorder previous order items (check availability first) | 1-2 days |
| ORD-004 | **Partial Refunds** | Refund specific items from an order | 2-3 days |
| ORD-005 | **Order Splitting** | Split order for multi-warehouse fulfillment | 2-3 days |
| ORD-006 | **Guest Checkout Enhancement** | Better guest-to-account conversion flow | 1-2 days |

#### 🧊 LOW PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| ORD-007 | **Subscription Orders** | Recurring orders for fabric supplies | 5+ days |
| ORD-008 | **Gift Wrapping** | Add gift wrap option with message | 1 day |

---

### ORD-001: Self-Service Returns Portal - Detailed Spec

**New Models:**
```go
type Return struct {
    ID            uuid.UUID `gorm:"type:uuid;primaryKey"`
    ReturnNumber  string    `gorm:"uniqueIndex;size:20"` // RET-20241215-001
    OrderID       uuid.UUID `gorm:"type:uuid;not null;index"`
    CustomerID    uuid.UUID `gorm:"type:uuid;not null;index"`

    // Return details
    Type          string `gorm:"size:20"` // return, exchange
    Reason        string `gorm:"size:50"` // wrong_size, defective, not_as_described, changed_mind
    ReasonDetails string

    // Status workflow
    Status        string    `gorm:"size:20;default:'pending'"`
    // pending -> approved -> shipped -> received -> refunded/exchanged
    // pending -> rejected

    // Timestamps
    RequestedAt   time.Time
    ApprovedAt    *time.Time
    ShippedAt     *time.Time
    ReceivedAt    *time.Time
    CompletedAt   *time.Time

    // Admin handling
    ApprovedBy    *uuid.UUID
    AdminNotes    string

    // Refund info
    RefundAmount  float64
    RefundStatus  string // pending, processed
    RefundID      *uuid.UUID

    // Return shipping
    ReturnLabel   string // URL to shipping label
    TrackingNumber string

    CreatedAt     time.Time
    UpdatedAt     time.Time
}

type ReturnItem struct {
    ID            uuid.UUID `gorm:"type:uuid;primaryKey"`
    ReturnID      uuid.UUID `gorm:"type:uuid;not null"`
    OrderItemID   uuid.UUID `gorm:"type:uuid;not null"`

    // What's being returned
    ProductID     uuid.UUID
    VariantID     *uuid.UUID
    ProductName   string
    VariantName   string
    Quantity      int
    UnitPrice     float64

    // For exchanges
    ExchangeVariantID *uuid.UUID
    ExchangeVariantName *string

    // Item status
    Status        string `gorm:"default:'pending'"` // pending, approved, rejected
    RejectionReason string

    CreatedAt     time.Time
}
```

**API Endpoints:**
```
# Customer
POST   /api/v1/orders/:id/returns           # Initiate return request
GET    /api/v1/customer/returns             # List my returns
GET    /api/v1/customer/returns/:id         # Get return details

# Admin
GET    /api/v1/admin/returns                # List all returns
GET    /api/v1/admin/returns/:id            # Get return details
PUT    /api/v1/admin/returns/:id/approve    # Approve return
PUT    /api/v1/admin/returns/:id/reject     # Reject return
PUT    /api/v1/admin/returns/:id/receive    # Mark items received
PUT    /api/v1/admin/returns/:id/complete   # Complete return (trigger refund)
```

---

## 5. FRONTEND-STOREFRONT Tasks

### Tasks to Implement

#### 🔥 HIGH PRIORITY

| ID | Task | Description | Effort | Status |
|----|------|-------------|--------|--------|
| FE-001 | **Variant Matrix on PDP** | Size/Color selector with real-time availability matrix | 2-3 days | ❌ |
| FE-002 | **Flash Sale Page** | Dedicated page with countdown, stock remaining | 2-3 days | ✅ DONE |
| FE-003 | **Faceted Search** | Filter by size, color, price, fabric, collection | 3-5 days | ❌ |
| FE-004 | **Size Guide Modal** | Interactive size guide with measurement tips | 1-2 days | ❌ |

#### 📦 MEDIUM PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| FE-005 | **Collections Landing** | Browse by collection (Raya 2024, Wedding, etc.) | 2 days |
| FE-006 | **Back-in-Stock Subscribe** | Button on OOS variants to get notified | 1 day |
| FE-007 | **Recently Viewed** | Show recently viewed products | 1 day |
| FE-008 | **Wishlist with Variants** | Save specific size/color combinations | 1-2 days |
| FE-009 | **Shop the Look** | Display coordinated outfit suggestions | 2 days |
| FE-010 | **Customer Account: Returns** | Self-service returns initiation | 2-3 days |

#### 🧊 LOW PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| FE-011 | **Style Quiz** | Onboarding quiz to set style preferences | 2-3 days |
| FE-012 | **Fabric Calculator** | Calculate meters needed for different garments | 1-2 days |
| FE-013 | **Loyalty Dashboard** | Show points balance, tier, rewards | 2 days |

---

## 6. FRONTEND-ADMIN Tasks

### Tasks to Implement

#### 🔥 HIGH PRIORITY

| ID | Task | Description | Effort | Status |
|----|------|-------------|--------|--------|
| ADM-001 | **Flash Sale Management** | Create/edit flash sales with item picker | 3-5 days | ✅ DONE |
| ADM-002 | **Variant Matrix Editor** | Bulk edit variants (generate combinations, bulk pricing) | 2-3 days | ❌ |
| ADM-003 | **Returns Management** | View, approve/reject returns, process refunds | 2-3 days | ❌ |

#### 📦 MEDIUM PRIORITY

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| ADM-004 | **Collection Builder** | Drag-drop products, set rules for auto-collections | 2-3 days |
| ADM-005 | **Lookbook Creator** | Build editorial lookbooks with product links | 2-3 days |
| ADM-006 | **Customer Style Profiles** | View customer preferences for personalization | 1-2 days |
| ADM-007 | **Low Stock Dashboard** | Enhanced alerts with reorder suggestions | 1-2 days |

---

## 7. NEW SERVICES (Optional)

### Consider for Scale

| ID | Service | Description | Priority |
|----|---------|-------------|----------|
| SVC-001 | **service-search** | Dedicated search with Meilisearch/Elasticsearch | Medium |
| SVC-002 | **service-recommendation** | ML-based product recommendations | Low |
| SVC-003 | **service-pricing** | Centralized pricing rules, flash sales, dynamic pricing | Medium |

---

## 8. INFRASTRUCTURE Tasks

| ID | Task | Description | Effort |
|----|------|-------------|--------|
| INFRA-001 | **Meilisearch Setup** | Deploy Meilisearch for faceted search | 1-2 days |
| INFRA-002 | **CDN for Images** | Cloudflare in front of MinIO | 1 day |
| INFRA-003 | **WebSocket Support** | Real-time stock updates on PDP | 2-3 days |
| INFRA-004 | **Redis Pub/Sub** | For real-time flash sale stock updates | 1-2 days |

---

## Implementation Roadmap

### Phase 1: Core Fashion Features (2-3 weeks)
Focus: Essential fashion eCommerce functionality

| Week | Tasks |
|------|-------|
| 1 | CAT-003 (Variant Availability API), CUS-001 (Variant Wishlist), FE-001 (Variant Matrix PDP) |
| 2 | CAT-001 (Flash Sale Engine), FE-002 (Flash Sale Page), ORD-002 (Flash Sale Validation) |
| 3 | CUS-002 (Back-in-Stock), INV-003 (Restock Events), FE-006 (Subscribe Button) |

### Phase 2: Discovery & Engagement (2-3 weeks)
Focus: Help customers find products

| Week | Tasks |
|------|-------|
| 4 | CAT-002 (Auto-Collections), FE-005 (Collections Landing), ADM-004 (Collection Builder) |
| 5 | FE-003 (Faceted Search), INFRA-001 (Meilisearch) |
| 6 | CAT-004 (Shop the Look), FE-009 (Shop the Look UI), CUS-003 (Style Preferences) |

### Phase 3: Operations & Retention (2-3 weeks)
Focus: Post-purchase experience

| Week | Tasks |
|------|-------|
| 7 | ORD-001 (Returns Portal), FE-010 (Customer Returns UI), ADM-003 (Returns Admin) |
| 8 | CUS-004 (Loyalty Points), FE-013 (Loyalty Dashboard) |
| 9 | CAT-005 (Lookbooks), ADM-005 (Lookbook Creator), ORD-003 (One-Click Reorder) |

---

## Quick Wins (Can Do This Week)

These tasks are small but impactful:

1. **FE-004: Size Guide Modal** (1-2 days) - Use existing size chart data
2. **FE-007: Recently Viewed** (1 day) - LocalStorage + API for logged-in users
3. **CUS-006: Recently Viewed Backend** (1 day) - Store in customer service
4. **CAT-008: Trending Products** (1-2 days) - Use existing view_count field
5. **FE-006: Back-in-Stock Button** (1 day) - UI only, backend in Phase 1

---

## Dependencies Graph

```
CAT-001 (Flash Sale Engine)
    └── ORD-002 (Flash Sale Validation)
    └── FE-002 (Flash Sale Page)
    └── INV-001 (Flash Sale Stock Lock)

CAT-003 (Variant Availability API)
    └── FE-001 (Variant Matrix PDP)

CUS-002 (Back-in-Stock Notifications)
    └── INV-003 (Restock Events)
    └── FE-006 (Subscribe Button)

ORD-001 (Returns Portal)
    └── FE-010 (Customer Returns UI)
    └── ADM-003 (Returns Admin)
    └── ORD-004 (Partial Refunds)

CUS-001 (Variant Wishlist)
    └── FE-008 (Wishlist with Variants)

INFRA-001 (Meilisearch)
    └── FE-003 (Faceted Search)
```

---

## Appendix: Existing Implementation Reference

### service-catalog
- Products: `internal/models/product.go`
- Variants: `internal/models/product_variant.go`
- Discounts: `internal/models/discount_model.go`
- Collections: `internal/models/cms.go` (FeaturedCollection)

### service-inventory
- Stock Items: `internal/models/stock_item.go`
- Warehouses: `internal/models/warehouse.go`
- Movements: `internal/models/stock_movement.go`
- Transfers: `internal/models/stock_transfer.go`

### service-customer
- Customer: `internal/models/customer.go`
- Wishlist: `internal/models/wishlist.go`
- Measurements: `internal/models/customer_measurement.go`
- Segments: `internal/models/customer.go` (CustomerSegment)

### service-order
- Cart: `internal/models/cart.go`
- Order: `internal/models/order.go`
- Payment: `internal/models/payment.go`
- Fulfillment: `internal/models/order.go` (Fulfillment struct)

---

**Document Version**: 1.0.0
**Last Updated**: 2024-12-15
**Related Docs**: [FASHION-ECOMMERCE-ARCHITECTURE.md](./FASHION-ECOMMERCE-ARCHITECTURE.md)
