# NIAGA PLATFORM - Coding Roadmap

## 📁 Repository Structure (1 Folder = 1 Repo)

| No  | Repo Name              | Type           | Priority    | Depends On                                       |
| --- | ---------------------- | -------------- | ----------- | ------------------------------------------------ |
| 1   | `infra-platform`       | Infrastructure | 🔴 Critical | -                                                |
| 2   | `infra-database`       | Database       | 🔴 Critical | -                                                |
| 3   | `lib-common`           | Shared Library | 🔴 Critical | -                                                |
| 4   | `service-auth`         | Backend        | 🔴 Critical | infra-database, lib-common                       |
| 5   | `service-catalog`      | Backend        | 🔴 Critical | service-auth                                     |
| 6   | `service-inventory`    | Backend        | 🟡 High     | service-auth, service-catalog                    |
| 7   | `service-order`        | Backend        | 🟡 High     | service-auth, service-catalog, service-inventory |
| 8   | `service-customer`     | Backend        | 🟡 High     | service-auth                                     |
| 9   | `service-notification` | Backend        | 🟢 Medium   | service-auth                                     |
| 10  | `service-agent`        | Backend        | 🟢 Medium   | service-auth, service-order                      |
| 11  | `service-reporting`    | Backend        | 🔵 Low      | All services                                     |
| 12  | `frontend-storefront`  | Frontend       | 🔴 Critical | service-auth, service-catalog                    |
| 13  | `frontend-admin`       | Frontend       | 🟡 High     | All backend services                             |
| 14  | `frontend-warehouse`   | Frontend       | 🟢 Medium   | service-inventory                                |
| 15  | `frontend-agent`       | Frontend       | 🟢 Medium   | service-agent                                    |
| 16  | `lib-ui`               | Shared Library | 🔵 Low      | -                                                |

---

## 🗓️ PHASE 1: Foundation (Week 1-2)✅

### Goal: Setup infrastructure & dapat run local development

| Day | Task                         | Repo             | Deliverable                                                      | Duration |
| --- | ---------------------------- | ---------------- | ---------------------------------------------------------------- | -------- |
| 1   | Setup Docker Compose         | `infra-platform` | Postgres, Redis, Meilisearch, MinIO, NATS running                | 2-3 jam  |
| 1   | Setup Traefik gateway        | `infra-platform` | API Gateway routing configured                                   | 1-2 jam  |
| 2   | Create database schemas      | `infra-database` | All tables created (auth, catalog, inventory, sales, crm, agent) | 3-4 jam  |
| 2   | Test database connection     | `infra-database` | Can connect & query via psql                                     | 1 jam    |
| 3   | Setup Go shared library      | `lib-common`     | Logger, database connector, response helper                      | 3-4 jam  |
| 3-4 | Create base service template | `lib-common`     | Reusable middleware, config loader                               | 2-3 jam  |

### ✅ Checkpoint Phase 1:

- [✅] `docker-compose up -d` runs successfully
- [✅] Can access PostgreSQL at localhost:5432
- [✅] Can access Redis at localhost:6379
- [✅] Can access Traefik dashboard at localhost:8081
- [✅] Database has all schemas & tables

---

## 🗓️ PHASE 2: Authentication Service (Week 2-3)✅

### Goal: Complete auth system dengan JWT

| Day | Task               | Repo           | Deliverable                                 | Duration |
| --- | ------------------ | -------------- | ------------------------------------------- | -------- |
| 5   | Project setup      | `service-auth` | Go project structure, dependencies          | 1-2 jam  |
| 5   | Database models    | `service-auth` | User, Session, PasswordReset models         | 2-3 jam  |
| 6   | Repository layer   | `service-auth` | CRUD operations for users                   | 3-4 jam  |
| 7   | Register endpoint  | `service-auth` | POST /api/v1/auth/register working          | 3-4 jam  |
| 8   | Login endpoint     | `service-auth` | POST /api/v1/auth/login with JWT            | 3-4 jam  |
| 9   | Token refresh      | `service-auth` | POST /api/v1/auth/refresh working           | 2-3 jam  |
| 9   | Logout endpoint    | `service-auth` | POST /api/v1/auth/logout (invalidate token) | 1-2 jam  |
| 10  | Password reset     | `service-auth` | Forgot password & reset flow                | 3-4 jam  |
| 11  | Auth middleware    | `service-auth` | JWT validation middleware                   | 2-3 jam  |
| 11  | Get/Update profile | `service-auth` | GET/PUT /api/v1/auth/me                     | 2-3 jam  |
| 12  | Unit tests         | `service-auth` | 80%+ coverage                               | 3-4 jam  |

### ✅ Checkpoint Phase 2:

- [✅] Can register new user
- [✅] Can login & receive JWT token
- [✅] Can refresh expired token
- [✅] Can reset password via email
- [✅] Protected routes require valid JWT
- [✅] All tests passing

### 📝 Auth Service Endpoints Checklist:

```
[✅] POST   /api/v1/auth/register
[✅] POST   /api/v1/auth/login
[✅] POST   /api/v1/auth/logout
[✅] POST   /api/v1/auth/refresh
[✅] POST   /api/v1/auth/forgot-password
[✅] POST   /api/v1/auth/reset-password
[✅] GET    /api/v1/auth/me
[✅] PUT    /api/v1/auth/me
[✅ ] POST   /api/v1/auth/change-password
[✅] GET    /api/v1/auth/verify (for other services)
```

---

## 🗓️ PHASE 3: Catalog Service (Week 4-5)✅

### Goal: Products & categories management dengan search

| Day | Task             | Repo              | Deliverable                             | Duration |
| --- | ---------------- | ----------------- | --------------------------------------- | -------- |
| 13  | Project setup    | `service-catalog` | Go project structure                    | 1-2 jam  |
| 13  | Database models  | `service-catalog` | Product, Category, Variant models       | 3-4 jam  |
| 14  | Category CRUD    | `service-catalog` | Create, read, update, delete categories | 4-5 jam  |
| 15  | Product CRUD     | `service-catalog` | Basic product management                | 4-5 jam  |
| 16  | Product variants | `service-catalog` | Size, color variants                    | 3-4 jam  |

| 17 | Product images | `service-catalog` | Upload to MinIO | 3-4 jam |
| 18 | Meilisearch setup | `service-catalog` | Index products for search | 3-4 jam |
| 19 | Search & filters | `service-catalog` | Search with facets | 4-5 jam |
| 20 | Public endpoints | `service-catalog` | List products, categories (no auth) | 2-3 jam |
| 21 | Unit tests | `service-catalog` | 80%+ coverage | 3-4 jam |

### ✅ Checkpoint Phase 3:

- [✅] Can create/edit/delete categories
- [✅] Can create/edit/delete products
- [✅] Can add product variants (sizes, colors)
- [✅] Can upload product images
- [✅] Search returns relevant results
- [✅] Filters work (price, category, attributes)

### 📝 Catalog Service Endpoints Checklist:

```
PUBLIC:
[✅] GET    /api/v1/catalog/products
[✅] GET /api/v1/catalog/products/:slug
[✅] GET /api/v1/catalog/products/:slug/variants
[✅] GET /api/v1/catalog/products/:slug/related
[✅] GET /api/v1/catalog/categories
[✅] GET /api/v1/catalog/categories/:slug
[✅] GET /api/v1/catalog/categories/:slug/products
[✅] GET /api/v1/catalog/filters
[✅] GET /api/v1/catalog/banners
[✅] GET /api/v1/search
[✅] GET /api/v1/search/suggestions

ADMIN (Protected):
[✅] POST /api/v1/catalog/admin/products
[✅] PUT /api/v1/catalog/admin/products/:id
[✅] DELETE /api/v1/catalog/admin/products/:id
[✅] POST /api/v1/catalog/admin/products/:id/images
[✅] POST /api/v1/catalog/admin/categories
[✅] PUT /api/v1/catalog/admin/categories/:id
[✅] DELETE /api/v1/catalog/admin/categories/:id

```

---

## 🗓️ PHASE 4: Inventory Service (Week 5-6)✅

### Goal: Stock management untuk semua warehouses

| Day | Task               | Repo                | Deliverable                         | Duration |
| --- | ------------------ | ------------------- | ----------------------------------- | -------- |
| 22  | Project setup      | `service-inventory` | Go project structure                | 1-2 jam  |
| 22  | Database models    | `service-inventory` | Warehouse, StockItem, StockMovement | 2-3 jam  |
| 23  | Warehouse CRUD     | `service-inventory` | Manage warehouses/branches          | 3-4 jam  |
| 24  | Stock items        | `service-inventory` | Track stock per warehouse           | 3-4 jam  |
| 25  | Stock movements    | `service-inventory` | Record in/out movements             | 3-4 jam  |
| 26  | Stock transfers    | `service-inventory` | Transfer between warehouses         | 4-5 jam  |
| 27  | Public stock check | `service-inventory` | Check availability (for storefront) | 2-3 jam  |
| 28  | NATS events        | `service-inventory` | Listen for order events             | 3-4 jam  |
| 29  | Unit tests         | `service-inventory` | 80%+ coverage                       | 3-4 jam  |

### ✅ Checkpoint Phase 4:

- [✅] Can manage warehouses
- [✅] Can track stock levels per warehouse
- [✅] Stock movements recorded correctly
- [✅] Can transfer stock between warehouses
- [✅] Public API returns stock availability
- [✅] Listens to order events & updates stock

### 📝 Inventory Service Endpoints Checklist:

```

PUBLIC:
[✅] GET /api/v1/inventory/availability/:productId
[✅] GET /api/v1/inventory/availability/:productId/:variantId
[✅] POST /api/v1/inventory/availability/bulk

ADMIN (Protected):
[✅] GET /api/v1/inventory/warehouses
[✅] POST /api/v1/inventory/warehouses
[✅] GET /api/v1/inventory/warehouses/:id
[✅] PUT /api/v1/inventory/warehouses/:id
[✅] GET /api/v1/inventory/stock
[✅] GET /api/v1/inventory/stock/:product_id
[✅] GET /api/v1/inventory/stock/low
[✅] POST /api/v1/inventory/stock/adjust
[✅] GET /api/v1/inventory/warehouses/:id/stock
[✅] GET /api/v1/inventory/movements
[✅] POST /api/v1/inventory/movements
[✅] GET /api/v1/inventory/movements/:id
[✅] GET /api/v1/inventory/products/:id/movements
[✅] GET /api/v1/inventory/transfers
[✅] POST /api/v1/inventory/transfers
[✅] GET /api/v1/inventory/transfers/:id
[✅] PUT /api/v1/inventory/transfers/:id/approve
[✅] PUT /api/v1/inventory/transfers/:id/complete
[✅] PUT /api/v1/inventory/transfers/:id/cancel

```

---

## 🗓️ PHASE 5: Frontend Storefront - Core (Week 6-8)

### Goal: Customer-facing website boleh browse & view products

| Day | Task              | Repo                  | Deliverable                         | Duration |
| --- | ----------------- | --------------------- | ----------------------------------- | -------- |
| 30  | Project setup     | `frontend-storefront` | Next.js 14, Tailwind, shadcn/ui     | 2-3 jam  |
| 30  | Layout components | `frontend-storefront` | Header, Footer, Navigation          | 3-4 jam  |
| 31  | Homepage          | `frontend-storefront` | Hero, featured products, categories | 4-5 jam  |
| 32  | Product listing   | `frontend-storefront` | Grid view with pagination           | 4-5 jam  |
| 33  | Filters & sorting | `frontend-storefront` | Filter sidebar, sort dropdown       | 4-5 jam  |
| 34  | Product detail    | `frontend-storefront` | Gallery, info, variants             | 5-6 jam  |
| 35  | Category pages    | `frontend-storefront` | Category listing & products         | 3-4 jam  |
| 36  | Search page       | `frontend-storefront` | Search with instant suggestions     | 4-5 jam  |
| 37  | Auth pages        | `frontend-storefront` | Login, register, forgot password    | 4-5 jam  |
| 38  | API integration   | `frontend-storefront` | Connect to backend services         | 3-4 jam  |
| 39  | Mobile responsive | `frontend-storefront` | Test & fix mobile views             | 3-4 jam  |

### ✅ Checkpoint Phase 5:

- [ ] Homepage loads with featured products
- [ ] Can browse product listing
- [ ] Filters & sorting work
- [ ] Product detail shows variants & stock
- [ ] Search returns results
- [ ] Can login/register
- [ ] Mobile responsive

### 📝 Storefront Pages Checklist:

```

[ ] / (Homepage)
[ ] /products (Product listing)
[ ] /products/[slug] (Product detail)
[ ] /categories/[slug] (Category page)
[ ] /search (Search results)
[ ] /login
[ ] /register
[ ] /forgot-password

```

---

## 🗓️ PHASE 6: Order & Cart Service (Week 8-9)

### Goal: Complete checkout flow

| Day | Task             | Repo            | Deliverable                      | Duration |
| --- | ---------------- | --------------- | -------------------------------- | -------- |
| 40  | Project setup    | `service-order` | Go project structure             | 1-2 jam  |
| 40  | Cart models      | `service-order` | Cart, CartItem models            | 2-3 jam  |
| 41  | Cart CRUD        | `service-order` | Add, update, remove items        | 4-5 jam  |
| 42  | Cart persistence | `service-order` | Guest cart (session) + user cart | 3-4 jam  |
| 43  | Order models     | `service-order` | Order, OrderItem, Payment        | 2-3 jam  |
| 44  | Checkout flow    | `service-order` | Create order from cart           | 4-5 jam  |
| 45  | Shipping methods | `service-order` | Calculate shipping cost          | 2-3 jam  |
| 46  | Order management | `service-order` | Update status, tracking          | 3-4 jam  |
| 47  | NATS events      | `service-order` | Publish order events             | 2-3 jam  |
| 48  | Payment stub     | `service-order` | Basic payment integration        | 3-4 jam  |
| 49  | Unit tests       | `service-order` | 80%+ coverage                    | 3-4 jam  |

### ✅ Checkpoint Phase 6:

- [ ] Can add/remove items from cart
- [ ] Cart persists for guests & users
- [ ] Can complete checkout
- [ ] Order created with correct totals
- [ ] Order status can be updated
- [ ] Events published to NATS

### 📝 Order Service Endpoints Checklist:

```

CART:
[ ] GET /api/v1/cart
[ ] POST /api/v1/cart/items
[ ] PUT /api/v1/cart/items/:itemId
[ ] DELETE /api/v1/cart/items/:itemId
[ ] DELETE /api/v1/cart
[ ] POST /api/v1/cart/coupon
[ ] DELETE /api/v1/cart/coupon

ORDER:
[ ] GET /api/v1/order (user's orders)
[ ] POST /api/v1/order (create order)
[ ] GET /api/v1/order/:id
[ ] GET /api/v1/order/:id/confirmation
[ ] POST /api/v1/order/:id/cancel

SHIPPING:
[ ] GET /api/v1/shipping/methods

PAYMENT:
[ ] POST /api/v1/payment/process
[ ] POST /api/v1/payment/webhook

```

---

## 🗓️ PHASE 7: Customer Service (Week 9-10)

### Goal: Customer profiles & addresses

| Day | Task               | Repo               | Deliverable                    | Duration |
| --- | ------------------ | ------------------ | ------------------------------ | -------- |
| 50  | Project setup      | `service-customer` | Go project structure           | 1-2 jam  |
| 50  | Customer models    | `service-customer` | Profile, Address, Wishlist     | 2-3 jam  |
| 51  | Profile CRUD       | `service-customer` | Get/update profile             | 2-3 jam  |
| 52  | Address management | `service-customer` | Add, edit, delete, set default | 4-5 jam  |
| 53  | Wishlist           | `service-customer` | Add/remove products            | 2-3 jam  |
| 54  | Order history      | `service-customer` | Link to orders                 | 2-3 jam  |
| 55  | Unit tests         | `service-customer` | 80%+ coverage                  | 2-3 jam  |

### 📝 Customer Service Endpoints Checklist:

```

[ ] GET /api/v1/customer/profile
[ ] PUT /api/v1/customer/profile
[ ] GET /api/v1/customer/addresses
[ ] POST /api/v1/customer/addresses
[ ] PUT /api/v1/customer/addresses/:id
[ ] DELETE /api/v1/customer/addresses/:id
[ ] PUT /api/v1/customer/addresses/:id/default
[ ] GET /api/v1/customer/wishlist
[ ] POST /api/v1/customer/wishlist
[ ] DELETE /api/v1/customer/wishlist/:productId

```

---

## 🗓️ PHASE 8: Frontend Storefront - Checkout (Week 10-11)

### Goal: Complete e-commerce flow

| Day | Task                | Repo                  | Deliverable                    | Duration |
| --- | ------------------- | --------------------- | ------------------------------ | -------- |
| 56  | Cart drawer         | `frontend-storefront` | Slide-out cart                 | 3-4 jam  |
| 57  | Cart page           | `frontend-storefront` | Full cart view                 | 3-4 jam  |
| 58  | Checkout - shipping | `frontend-storefront` | Address form, method selection | 4-5 jam  |
| 59  | Checkout - payment  | `frontend-storefront` | Payment method selection       | 3-4 jam  |
| 60  | Checkout - review   | `frontend-storefront` | Order review & confirm         | 3-4 jam  |
| 61  | Order confirmation  | `frontend-storefront` | Success page                   | 2-3 jam  |
| 62  | Account dashboard   | `frontend-storefront` | Overview, quick links          | 3-4 jam  |
| 63  | Order history       | `frontend-storefront` | List & detail view             | 4-5 jam  |
| 64  | Address book        | `frontend-storefront` | Manage addresses               | 3-4 jam  |
| 65  | Wishlist            | `frontend-storefront` | View & manage wishlist         | 2-3 jam  |

### ✅ Checkpoint Phase 8:

- [ ] Can add to cart from product page
- [ ] Cart shows correct items & totals
- [ ] Can complete full checkout flow
- [ ] Order confirmation shows details
- [ ] Can view order history
- [ ] Can manage addresses

### 📝 Additional Storefront Pages Checklist:

```

[ ] /cart
[ ] /checkout
[ ] /order-complete/[orderId]
[ ] /account
[ ] /account/orders
[ ] /account/orders/[orderId]
[ ] /account/addresses
[ ] /account/profile
[ ] /wishlist

```

---

## 🗓️ PHASE 9: Admin Dashboard (Week 11-13)

### Goal: Complete admin panel

| Day | Task            | Repo             | Deliverable             | Duration |
| --- | --------------- | ---------------- | ----------------------- | -------- |
| 66  | Project setup   | `frontend-admin` | Next.js, auth, layout   | 3-4 jam  |
| 67  | Dashboard home  | `frontend-admin` | Overview, stats, charts | 4-5 jam  |
| 68  | Products list   | `frontend-admin` | Table with filters      | 4-5 jam  |
| 69  | Product form    | `frontend-admin` | Create/edit product     | 5-6 jam  |
| 70  | Categories      | `frontend-admin` | Tree view, CRUD         | 4-5 jam  |
| 71  | Orders list     | `frontend-admin` | Table with status       | 4-5 jam  |
| 72  | Order detail    | `frontend-admin` | View & update order     | 4-5 jam  |
| 73  | Customers       | `frontend-admin` | List & detail view      | 3-4 jam  |
| 74  | Inventory       | `frontend-admin` | Stock overview          | 4-5 jam  |
| 75  | Warehouses      | `frontend-admin` | Manage warehouses       | 3-4 jam  |
| 76  | Stock transfers | `frontend-admin` | Create & approve        | 4-5 jam  |
| 77  | Settings        | `frontend-admin` | Store settings          | 3-4 jam  |

### ✅ Checkpoint Phase 9:

- [ ] Admin can login
- [ ] Dashboard shows key metrics
- [ ] Can manage products & categories
- [ ] Can view & update orders
- [ ] Can manage inventory
- [ ] Can manage warehouses & transfers

---

## 🗓️ PHASE 10: Notification Service (Week 13-14)

### Goal: Email & notification system

| Day | Task             | Repo                   | Deliverable                    | Duration |
| --- | ---------------- | ---------------------- | ------------------------------ | -------- |
| 78  | Project setup    | `service-notification` | Go project, NATS listener      | 2-3 jam  |
| 79  | Email templates  | `service-notification` | Order, password reset, welcome | 3-4 jam  |
| 80  | SMTP integration | `service-notification` | Send actual emails             | 2-3 jam  |
| 81  | Event handlers   | `service-notification` | Listen & process events        | 3-4 jam  |
| 82  | SMS stub         | `service-notification` | SMS provider integration       | 2-3 jam  |

---

## 🗓️ PHASE 11: Agent System (Week 14-15)

### Goal: Agent/reseller management

| Day | Task               | Repo             | Deliverable                   | Duration |
| --- | ------------------ | ---------------- | ----------------------------- | -------- |
| 83  | Project setup      | `service-agent`  | Go project structure          | 1-2 jam  |
| 84  | Agent models       | `service-agent`  | Agent, Commission, Payout     | 2-3 jam  |
| 85  | Agent registration | `service-agent`  | Create agent profiles         | 3-4 jam  |
| 86  | Commission calc    | `service-agent`  | Calculate from orders         | 4-5 jam  |
| 87  | Payout system      | `service-agent`  | Track payouts                 | 3-4 jam  |
| 88  | Agent frontend     | `frontend-agent` | Dashboard, orders, commission | 5-6 jam  |

---

## 🗓️ PHASE 12: Warehouse App (Week 15-16)

### Goal: WMS for warehouse staff

| Day | Task          | Repo                 | Deliverable             | Duration |
| --- | ------------- | -------------------- | ----------------------- | -------- |
| 89  | Project setup | `frontend-warehouse` | Next.js PWA             | 2-3 jam  |
| 90  | Receiving     | `frontend-warehouse` | Record stock in         | 4-5 jam  |
| 91  | Picking       | `frontend-warehouse` | Order picking interface | 4-5 jam  |
| 92  | Packing       | `frontend-warehouse` | Pack & print label      | 3-4 jam  |
| 93  | Stock take    | `frontend-warehouse` | Inventory count         | 3-4 jam  |
| 94  | Transfers     | `frontend-warehouse` | Process transfers       | 3-4 jam  |

---

## 🗓️ PHASE 13: Reporting & Polish (Week 16-18)

### Goal: Analytics & production ready

| Day | Task              | Repo                | Deliverable               | Duration |
| --- | ----------------- | ------------------- | ------------------------- | -------- |
| 95  | Reporting service | `service-reporting` | Sales, inventory reports  | 4-5 jam  |
| 96  | Dashboard charts  | `frontend-admin`    | Revenue, orders charts    | 4-5 jam  |
| 97  | Performance       | All                 | Optimize queries, caching | 3-4 jam  |
| 98  | Security audit    | All                 | Check vulnerabilities     | 3-4 jam  |
| 99  | Documentation     | All                 | API docs, README          | 3-4 jam  |
| 100 | Production deploy | `infra-platform`    | Deploy to VPS             | 4-5 jam  |

---

## 📊 Summary Timeline

| Phase | Duration   | Focus                     |
| ----- | ---------- | ------------------------- |
| 1     | Week 1-2   | Infrastructure & Database |
| 2     | Week 2-3   | Auth Service              |
| 3     | Week 4-5   | Catalog Service           |
| 4     | Week 5-6   | Inventory Service         |
| 5     | Week 6-8   | Storefront Core           |
| 6     | Week 8-9   | Order Service             |
| 7     | Week 9-10  | Customer Service          |
| 8     | Week 10-11 | Storefront Checkout       |
| 9     | Week 11-13 | Admin Dashboard           |
| 10    | Week 13-14 | Notifications             |
| 11    | Week 14-15 | Agent System              |
| 12    | Week 15-16 | Warehouse App             |
| 13    | Week 16-18 | Reporting & Deploy        |

**Total: ~18 weeks (4.5 months)**

---

## 🚀 Quick Start - Day 1

```bash
# 1. Clone/create infra-platform repo
mkdir niaga-platform && cd niaga-platform
git init infra-platform

# 2. Setup docker-compose
cd infra-platform
# Copy docker-compose.dev.yml dari template

# 3. Start infrastructure
docker-compose -f docker-compose.dev.yml up -d

# 4. Verify all running
docker ps

# 5. Test database
docker exec -it niaga-postgres psql -U niaga -d niaga -c "SELECT 'Connected!' as status;"
```

**Selamat coding! 💪**
