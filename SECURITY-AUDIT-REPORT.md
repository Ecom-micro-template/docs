# Security Audit Report - Kilang Desa Murni Batik

## Enterprise Production Readiness Audit

**Audit Date:** December 15, 2024
**Auditor:** Enterprise System Audit
**Platform:** Kilang Desa Murni Batik E-Commerce
**Architecture:** Go Microservices + Next.js 14 + PostgreSQL
**Infrastructure:** Docker Compose, Nginx, VPS (4GB RAM, 2 vCPU)

---

## Executive Summary

| Category | Status |
|----------|--------|
| **Overall Assessment** | **NOT PRODUCTION READY** |
| Critical Issues | 5 |
| High Severity Issues | 5 |
| Medium Severity Issues | 5 |
| Low Severity Issues | 3 |

The platform has solid foundational architecture but contains **critical security vulnerabilities** that must be addressed before handling real customer transactions.

---

## Table of Contents

1. [Critical Issues](#1-critical-issues-blocks-production)
2. [High Severity Issues](#2-high-severity-issues)
3. [Medium Severity Issues](#3-medium-severity-issues)
4. [Low Severity Issues](#4-low-severity-issues)
5. [What's Working Well](#5-whats-working-well)
6. [Scalability Analysis](#6-scalability-analysis)
7. [Compliance Gaps](#7-compliance-gaps)
8. [Recommended Action Plan](#8-recommended-action-plan)

---

## 1. Critical Issues (Blocks Production)

### 1.1 Production Secrets Committed to Git Repository

**Severity:** CRITICAL
**Location:** `infra-platform/.env`

**Finding:**
```
POSTGRES_PASSWORD=t3NzZodU6lGCvfrVAL8paM5O
JWT_SECRET=E5S8QM3q5c6xhOp3mijvcXp34oiEvmeJ6VxTRZBEi1PluYWdKg6IWP/ErCT7V4qC
MINIO_ROOT_PASSWORD=PAO3Wz5LhwYNq6DRaf8cUdmX
```

**Business Risk:**
Anyone with repository access has full access to production database, can forge authentication tokens for any user, and access all stored files.

**Remediation:**
```bash
# 1. IMMEDIATELY rotate all secrets in production
# 2. Remove from git history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch infra-platform/.env' \
  --prune-empty --tag-name-filter cat -- --all

# 3. Add to .gitignore
echo "infra-platform/.env" >> .gitignore
echo "**/.env" >> .gitignore
echo "!**/.env.example" >> .gitignore
```

**Status:** [ ] Not Fixed

---

### 1.2 Password Reset Token Exposed in Response

**Severity:** CRITICAL
**Location:** `service-auth/internal/handlers/auth_handler.go:320-327`

**Finding:**
```go
if reset != nil {
    // DEV ONLY: Include token in response
    data["reset_token"] = reset.Token  // CRITICAL: REMOVE THIS
}
```

**Business Risk:**
Attackers can take over ANY account by requesting password reset and using the token returned in the response.

**Remediation:**
```go
func (h *AuthHandler) ForgotPassword(c *gin.Context) {
    // ... existing validation code ...

    reset, err := h.authService.RequestPasswordReset(req.Email)
    if err != nil {
        h.logger.Error("Password reset request failed", zap.Error(err))
    }

    // Send email asynchronously - NEVER return token in response
    if reset != nil {
        go h.sendPasswordResetEmail(req.Email, reset.Token)
    }

    // Always return same response (prevents email enumeration)
    response.OK(c, "If the email exists, a password reset link has been sent", nil)
}
```

**Status:** [ ] Not Fixed

---

### 1.3 JWT Permission Check Bypassed in Frontend Middleware

**Severity:** CRITICAL
**Location:** `frontend-admin/middleware.ts:169-176`

**Finding:**
```typescript
// TODO: In production, decode JWT here and check permissions server-side
// For now, we rely on client-side permission checks
// ...
return NextResponse.next();  // ALWAYS ALLOWS ACCESS
```

**Business Risk:**
ANY authenticated user can access ANY admin route. A customer account can access `/users`, `/settings`, order management, and financial reports.

**Remediation:**
```typescript
import { jwtVerify } from 'jose';

export async function middleware(request: NextRequest) {
    const { pathname } = request.nextUrl;

    if (PUBLIC_ROUTES.some((route) => pathname.startsWith(route))) {
        return NextResponse.next();
    }

    const token = request.cookies.get('admin_token')?.value;
    if (!token) {
        return NextResponse.redirect(new URL('/login', request.url));
    }

    try {
        const secret = new TextEncoder().encode(process.env.JWT_SECRET);
        const { payload } = await jwtVerify(token, secret);

        const requiredPermissions = getRequiredPermissions(pathname);
        if (requiredPermissions && requiredPermissions.length > 0) {
            const userPermissions = payload.permissions as string[] || [];
            if (!hasRequiredPermissions(userPermissions, requiredPermissions)) {
                return NextResponse.redirect(new URL('/unauthorized', request.url));
            }
        }

        return NextResponse.next();
    } catch (error) {
        return NextResponse.redirect(new URL('/login', request.url));
    }
}
```

**Status:** [ ] Not Fixed

---

### 1.4 Shared Database - Microservices Anti-Pattern

**Severity:** CRITICAL
**Location:** `infra-platform/docker-compose.vps.yml`

**Finding:**
All 8 services connect to the same database with the same credentials:
```yaml
service-auth:      DB_NAME=${POSTGRES_DB:-kilang_batik}
service-catalog:   DB_NAME=${POSTGRES_DB:-kilang_batik}
service-inventory: DB_NAME=${POSTGRES_DB:-kilang_batik}
service-order:     DB_NAME=${POSTGRES_DB:-kilang_batik}
# ... ALL services share the SAME database
```

**Business Risk:**
This is a "Distributed Monolith". Any service can directly query/modify data owned by other services, bypassing business logic.

**Remediation (Phase 1 - Schema Isolation):**
```sql
-- Create dedicated users per service
CREATE USER auth_service WITH PASSWORD 'xxx';
CREATE USER catalog_service WITH PASSWORD 'xxx';

-- Grant only necessary permissions
GRANT ALL ON SCHEMA auth TO auth_service;
GRANT SELECT ON catalog.products TO order_service; -- Read-only for lookups

-- Revoke cross-schema access
REVOKE ALL ON SCHEMA orders FROM catalog_service;
```

**Status:** [ ] Not Fixed

---

### 1.5 No SSL/TLS in Production

**Severity:** CRITICAL
**Location:** `infra-platform/nginx/nginx.conf:132-135`

**Finding:**
```nginx
# Redirect all HTTP to HTTPS (uncomment when SSL is ready)
# location / {
#     return 301 https://$host$request_uri;
# }
```

**Business Risk:**
All traffic including passwords and payment data transmitted in plaintext. Violates PCI-DSS.

**Remediation:**
```bash
# Install certbot and get certificate
apt install certbot
certbot certonly --webroot -w /var/www/certbot -d yourdomain.com

# Enable HTTPS in nginx.conf - uncomment SSL server block
```

**Status:** [ ] Not Fixed

---

## 2. High Severity Issues

### 2.1 In-Memory Idempotency Loses Data on Restart

**Severity:** HIGH
**Location:** `service-inventory/internal/events/idempotency.go:17-26`

**Finding:**
```go
type IdempotencyChecker struct {
    processed map[string]time.Time  // IN-MEMORY - lost on restart
    mu        sync.RWMutex
    ttl       time.Duration
}
```

**Business Risk:**
After service restart, duplicate events will be processed. During flash sale, inventory could be double-decremented.

**Remediation:**
```go
type RedisIdempotencyChecker struct {
    client *redis.Client
    ttl    time.Duration
}

func (ic *RedisIdempotencyChecker) IsProcessed(eventID string) bool {
    key := fmt.Sprintf("idempotency:%s", eventID)
    exists, _ := ic.client.Exists(context.Background(), key).Result()
    return exists > 0
}

func (ic *RedisIdempotencyChecker) MarkProcessed(eventID string) {
    key := fmt.Sprintf("idempotency:%s", eventID)
    ic.client.Set(context.Background(), key, "1", ic.ttl)
}
```

**Status:** [ ] Not Fixed

---

### 2.2 No Payment Idempotency Keys

**Severity:** HIGH
**Location:** `service-order/internal/services/payment_service.go:136-162`

**Finding:**
```go
func (s *paymentService) ProcessPayment(orderID uuid.UUID, ...) (*PaymentResult, error) {
    // No idempotency check - network retry = duplicate payment!
    payment := &models.Payment{...}
    if err := s.paymentRepo.CreatePayment(payment); err != nil {
        return nil, err
    }
}
```

**Business Risk:**
Network timeout during payment leads to customer retry and double charge.

**Remediation:**
```go
func (s *paymentService) ProcessPayment(orderID uuid.UUID, ..., idempotencyKey string) (*PaymentResult, error) {
    // Check if already processed
    existing, err := s.paymentRepo.GetPaymentByIdempotencyKey(idempotencyKey)
    if err == nil && existing != nil {
        return &PaymentResult{
            Success:   existing.Status == models.PaymentStatusCompleted,
            PaymentID: existing.ID.String(),
            Message:   "Payment already processed (idempotent)",
        }, nil
    }
    // Continue with payment...
}
```

**Status:** [ ] Not Fixed

---

### 2.3 Panic Error Leaks Internal Details

**Severity:** HIGH
**Location:** `lib-common/middleware/recovery.go:27-28`

**Finding:**
```go
response.Error(c, http.StatusInternalServerError, "INTERNAL_SERVER_ERROR",
    fmt.Sprintf("Internal server error: %v", err), nil)  // LEAKS err to client
```

**Business Risk:**
Stack traces and internal paths exposed to attackers.

**Remediation:**
```go
// Log full details internally
logger.Error("Panic recovered",
    zap.Any("error", err),
    zap.String("stack", string(debug.Stack())),
    zap.String("request_id", c.GetString("request_id")),
)

// Return generic error to client
response.Error(c, http.StatusInternalServerError, "INTERNAL_SERVER_ERROR",
    "An unexpected error occurred. Reference: " + c.GetString("request_id"), nil)
```

**Status:** [ ] Not Fixed

---

### 2.4 JWT Token Stored in LocalStorage

**Severity:** HIGH
**Location:** `frontend-admin/src/lib/api/auth.ts:32-35`

**Finding:**
```typescript
const getAuthToken = (): string | null => {
    if (typeof window !== 'undefined') {
        return localStorage.getItem('admin_token');  // XSS-vulnerable
    }
    return null;
};
```

**Business Risk:**
Any XSS vulnerability allows token theft.

**Remediation:**
```typescript
// Use httpOnly cookies instead - set from backend:
c.SetCookie("access_token", accessToken, 900, "/", "", true, true)  // httpOnly, secure

// Frontend: cookies sent automatically
async function loginAdmin(credentials: LoginCredentials): Promise<AuthResponse> {
    const response = await fetch(`${API_URL}/auth/login`, {
        method: 'POST',
        credentials: 'include',  // Send/receive cookies
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(credentials),
    });
}
```

**Status:** [ ] Not Fixed

---

### 2.5 Hardcoded Default Passwords in Docker Compose

**Severity:** HIGH
**Location:** `infra-platform/docker-compose.vps.yml:79-80`

**Finding:**
```yaml
POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-kilang123}  # Default password!
```

**Business Risk:**
If .env file missing, production runs with weak default password.

**Remediation:**
```yaml
# Make secrets required - fail loudly if not set
services:
  postgres:
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}
```

**Status:** [ ] Not Fixed

---

## 3. Medium Severity Issues

### 3.1 No Zero-Downtime Deployment Strategy

**Severity:** MEDIUM
**Location:** Docker Compose configuration

**Business Risk:**
Every deployment causes service interruption.

**Remediation:**
```yaml
services:
  service-order:
    deploy:
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
        order: start-first
      rollback_config:
        parallelism: 1
        delay: 10s
    healthcheck:
      start_period: 30s
```

**Status:** [ ] Not Fixed

---

### 3.2 Connection Pool May Exhaust Under Load

**Severity:** MEDIUM
**Location:** `lib-common/database/postgres.go:59-61`

**Finding:**
```go
sqlDB.SetMaxOpenConns(100)  // 8 services × 100 = 800 connections
```

**Business Risk:**
8 services × 100 connections = 800 potential connections. PostgreSQL default is 100.

**Remediation:**
```go
sqlDB.SetMaxIdleConns(5)
sqlDB.SetMaxOpenConns(20)  // 8 services × 20 = 160
sqlDB.SetConnMaxIdleTime(5 * time.Minute)
sqlDB.SetConnMaxLifetime(30 * time.Minute)
```

**Status:** [ ] Not Fixed

---

### 3.3 No Distributed Transaction / Saga Pattern

**Severity:** MEDIUM
**Location:** `service-order/internal/services/stock_reservation.go`

**Business Risk:**
If payment fails after inventory reservation, manual cleanup required.

**Remediation:**
Implement Saga pattern with compensating transactions via NATS.

**Status:** [ ] Not Fixed

---

### 3.4 Rate Limiting Too Generous for Login

**Severity:** MEDIUM
**Location:** `infra-platform/nginx/nginx.conf:48`

**Finding:**
```nginx
limit_req_zone $binary_remote_addr zone=login_limit:10m rate=5r/m;
```

**Business Risk:**
5 requests per minute per IP, but attacker can use multiple IPs.

**Remediation:**
Add account-based rate limiting in auth service:
```go
func (h *AuthHandler) Login(c *gin.Context) {
    key := fmt.Sprintf("login_attempts:%s", req.Email)
    attempts, _ := h.redis.Incr(context.Background(), key).Result()
    h.redis.Expire(context.Background(), key, 15*time.Minute)

    if attempts > 5 {
        response.TooManyRequests(c, "Too many login attempts.")
        return
    }
}
```

**Status:** [ ] Not Fixed

---

### 3.5 No Request Body Logging Sanitization

**Severity:** MEDIUM
**Location:** `service-auth/internal/middleware/audit_logger.go:46-53`

**Business Risk:**
PII (customer addresses, phone numbers) may be logged.

**Remediation:**
```go
func sanitizeRequestBody(body string) string {
    patterns := map[string]*regexp.Regexp{
        "email":    regexp.MustCompile(`"email"\s*:\s*"[^"]+"`),
        "phone":    regexp.MustCompile(`"phone"\s*:\s*"[^"]+"`),
        "password": regexp.MustCompile(`"password"\s*:\s*"[^"]+"`),
    }

    result := body
    for field, pattern := range patterns {
        result = pattern.ReplaceAllString(result, fmt.Sprintf(`"%s":"[REDACTED]"`, field))
    }
    return result
}
```

**Status:** [ ] Not Fixed

---

## 4. Low Severity Issues

### 4.1 Missing Token Type Differentiation

**Severity:** LOW
**Location:** `lib-common/auth/jwt.go:67-83`

**Finding:**
Access and refresh tokens use same structure.

**Remediation:**
Add `Type` claim to differentiate token types.

**Status:** [ ] Not Fixed

---

### 4.2 No Circuit Breaker on HTTP Calls

**Severity:** LOW
**Location:** Inter-service HTTP calls

**Finding:**
Circuit breaker exists for NATS but not HTTP calls between services.

**Remediation:**
Use `github.com/sony/gobreaker` for HTTP clients.

**Status:** [ ] Not Fixed

---

### 4.3 Missing Structured Error Codes

**Severity:** LOW
**Location:** Various error responses

**Finding:**
Error messages are inconsistent.

**Remediation:**
```go
type AppError struct {
    Code    string `json:"code"`
    Message string `json:"message"`
    Details any    `json:"details,omitempty"`
}

var (
    ErrInsufficientStock = &AppError{Code: "INV_001", Message: "Insufficient stock"}
    ErrPaymentDeclined   = &AppError{Code: "PAY_001", Message: "Payment declined"}
)
```

**Status:** [ ] Not Fixed

---

## 5. What's Working Well

| Feature | Location | Assessment |
|---------|----------|------------|
| Row-level locking | `stock_repository.go:157` | Proper `SELECT FOR UPDATE` |
| Circuit breaker | `service-inventory/internal/events/circuit_breaker.go` | Well implemented for NATS |
| Audit logging | `service-auth/internal/middleware/audit_logger.go` | DB persistence implemented |
| 2FA support | `service-auth` | TOTP with backup codes |
| RBAC system | `service-auth` | Proper permissions model |
| Resource limits | `docker-compose.vps.yml` | Memory/CPU limits set |
| Health checks | All services | Implemented |
| Rate limiting | `nginx.conf` | Nginx level limiting |
| Security headers | `nginx.conf` | CSP, X-Frame-Options, etc. |
| Structured logging | All services | Zap logger properly used |

---

## 6. Scalability Analysis

### What Breaks at 10x Load?

| Component | Current Capacity | 10x Bottleneck | Fix |
|-----------|------------------|----------------|-----|
| PostgreSQL | Single instance, 100 conns | Connection exhaustion | Add read replicas, PgBouncer |
| Redis | 128MB, no cluster | Memory exhaustion | Increase memory, Redis Cluster |
| Nginx | 1024 connections | Worker exhaustion | Increase to 4096, add caching |
| Single VPS | 4GB RAM, 2 CPU | Resource competition | Separate DB server |
| MinIO | Single node | Disk I/O, SPOF | Add replication or managed S3 |

---

## 7. Compliance Gaps

### PCI-DSS Violations (if handling card data)
- [ ] No encryption in transit (HTTP, not HTTPS)
- [ ] Secrets in version control
- [ ] No network segmentation
- [ ] Default credentials in config
- [x] Audit logging present (needs PII sanitization)

### PDPA (Malaysia) Considerations
- [ ] Customer data logged without sanitization
- [ ] No data retention policy visible
- [ ] No customer data export/deletion capability visible

---

## 8. Recommended Action Plan

### Week 1 - Critical Security
- [ ] Rotate ALL production secrets immediately
- [ ] Remove secrets from git history
- [ ] Enable HTTPS
- [ ] Fix JWT middleware bypass
- [ ] Remove password reset token from response

### Week 2 - High Priority
- [ ] Implement payment idempotency
- [ ] Move idempotency to Redis
- [ ] Fix panic error leaks
- [ ] Switch to httpOnly cookies

### Week 3-4 - Architecture
- [ ] Implement proper service isolation
- [ ] Add health check grace periods
- [ ] Tune connection pools
- [ ] Add distributed tracing

### Ongoing
- [ ] Security audit quarterly
- [ ] Load testing before major sales
- [ ] Implement Saga pattern
- [ ] Plan database separation

---

## Audit Sign-off

| Item | Status |
|------|--------|
| Critical issues identified | Yes |
| Remediation provided | Yes |
| Business risk explained | Yes |
| Ready for production | **NO** |

**Recommendation:** Do NOT go live until all CRITICAL issues are fixed.

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-12-15 | Initial security audit |

---

**Note:** This audit should be repeated after critical fixes are implemented and before any production deployment.
