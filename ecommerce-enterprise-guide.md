# Enterprise E-Commerce Platform - Development Guide

## Project Codename: "Niaga" (atau nama pilihan awak)

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Repository Structure](#repository-structure)
3. [Tech Stack Complete](#tech-stack-complete)
4. [Storefront Pages & Components](#storefront-pages--components)
5. [API Endpoints Required](#api-endpoints-required)
6. [Database Schema](#database-schema)
7. [Infrastructure Setup](#infrastructure-setup)
8. [Development Workflow](#development-workflow)
9. [Phase 1 Implementation Checklist](#phase-1-implementation-checklist)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              CLIENTS                                         │
├─────────────────┬─────────────────┬─────────────────┬───────────────────────┤
│   Storefront    │  Admin Portal   │   WMS App       │    Agent App          │
│   (Next.js)     │  (Next.js)      │   (Next.js)     │    (Next.js PWA)      │
└────────┬────────┴────────┬────────┴────────┬────────┴───────────┬───────────┘
         │                 │                 │                     │
         └─────────────────┴─────────────────┴─────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY (Traefik)                                │
│                    SSL Termination, Rate Limiting, Auth                      │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
         ┌────────────────────────────┼────────────────────────────┐
         │                            │                            │
         ▼                            ▼                            ▼
┌─────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
│  Auth Service   │      │  Catalog Service    │      │  Inventory Service  │
│  (Go + Gin)     │      │  (Go + Gin)         │      │  (Go + Gin)         │
│  Port: 8001     │      │  Port: 8002         │      │  Port: 8003         │
└────────┬────────┘      └──────────┬──────────┘      └──────────┬──────────┘
         │                          │                            │
         │               ┌──────────┴──────────┐                 │
         │               ▼                     ▼                 │
         │      ┌─────────────────┐   ┌─────────────────┐        │
         │      │  Order Service  │   │ Customer Service│        │
         │      │  (Go + Gin)     │   │  (Go + Gin)     │        │
         │      │  Port: 8004     │   │  Port: 8005     │        │
         │      └────────┬────────┘   └────────┬────────┘        │
         │               │                     │                 │
         └───────────────┴──────────┬──────────┴─────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MESSAGE BROKER (NATS)                              │
│                     Event-driven async communication                         │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
         ┌────────────────────────────┼────────────────────────────┐
         ▼                            ▼                            ▼
┌─────────────────┐      ┌─────────────────────┐      ┌─────────────────────┐
│  Notification   │      │  Reporting Service  │      │   Agent Service     │
│  Service        │      │  (Go + Gin)         │      │   (Go + Gin)        │
│  Port: 8006     │      │  Port: 8007         │      │   Port: 8008        │
└─────────────────┘      └─────────────────────┘      └─────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DATA LAYER                                        │
├─────────────────┬─────────────────┬─────────────────┬───────────────────────┤
│   PostgreSQL    │     Redis       │   Meilisearch   │      MinIO           │
│   (Primary DB)  │    (Cache)      │   (Search)      │   (File Storage)     │
│   Port: 5432    │   Port: 6379    │   Port: 7700    │   Port: 9000         │
└─────────────────┴─────────────────┴─────────────────┴───────────────────────┘
```

---

## Repository Structure

### GitHub/Gitea Organization: `niaga-platform`

```
niaga-platform/
│
├── 🏗️ INFRASTRUCTURE
│   ├── infra-platform/              # DevOps & Infrastructure
│   │   ├── docker/                  # Docker configs
│   │   ├── traefik/                 # API Gateway config
│   │   ├── scripts/                 # Deployment scripts
│   │   ├── monitoring/              # Grafana, Prometheus configs
│   │   └── docker-compose.prod.yml
│   │
│   └── infra-database/              # Database migrations & seeds
│       ├── migrations/
│       ├── seeds/
│       └── scripts/
│
├── 🔧 BACKEND SERVICES
│   ├── service-auth/                # Authentication & Authorization
│   ├── service-catalog/             # Products & Categories
│   ├── service-inventory/           # Stock & Warehouse
│   ├── service-order/               # Orders & Checkout
│   ├── service-customer/            # Customer Management
│   ├── service-agent/               # Agent & Commission
│   ├── service-notification/        # Email, SMS, Push
│   └── service-reporting/           # Analytics & Reports
│
├── 🎨 FRONTEND APPLICATIONS
│   ├── frontend-storefront/         # Customer Website
│   ├── frontend-admin/              # HQ Admin Dashboard
│   ├── frontend-warehouse/          # WMS Interface
│   └── frontend-agent/              # Agent Mobile App (PWA)
│
└── 📦 SHARED LIBRARIES
    ├── lib-common/                  # Shared Go utilities
    ├── lib-proto/                   # gRPC Proto files (optional)
    └── lib-ui/                      # Shared UI components
```

---

## Tech Stack Complete

### Backend Services

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Language | Go | 1.22+ | Main backend language |
| Framework | Gin | 1.9+ | HTTP framework |
| ORM | GORM | 1.25+ | Database ORM |
| Validation | go-playground/validator | 10+ | Input validation |
| JWT | golang-jwt/jwt | 5+ | Token handling |
| Config | Viper | 1.18+ | Configuration management |
| Logging | Zap | 1.27+ | Structured logging |
| Testing | Testify | 1.8+ | Testing framework |

### Frontend Applications

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Framework | Next.js | 14+ (App Router) | React framework |
| Language | TypeScript | 5+ | Type safety |
| Styling | Tailwind CSS | 3.4+ | Utility CSS |
| Components | shadcn/ui | latest | UI components |
| State | Zustand | 4+ | State management |
| Forms | React Hook Form | 7+ | Form handling |
| Validation | Zod | 3+ | Schema validation |
| HTTP Client | Axios / Fetch | - | API calls |
| Icons | Lucide React | latest | Icon library |

### Data Layer

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Database | PostgreSQL | 16+ | Primary database |
| Cache | Redis | 7+ | Caching & sessions |
| Search | Meilisearch | 1.6+ | Product search |
| Queue | NATS | 2.10+ | Message broker |
| Storage | MinIO | latest | S3-compatible storage |

### Infrastructure

| Component | Technology | Version | Purpose |
|-----------|------------|---------|---------|
| Container | Docker | 24+ | Containerization |
| Orchestration | Docker Swarm | - | Container orchestration |
| Gateway | Traefik | 3+ | Reverse proxy & SSL |
| Monitoring | Grafana + Prometheus | latest | Metrics & dashboards |
| Logging | Loki | latest | Log aggregation |
| CI/CD | GitHub Actions | - | Automation |

---

## Storefront Pages & Components

### Page Structure & Tech Requirements

```
frontend-storefront/
├── app/
│   ├── (shop)/                      # Shop layout group
│   │   ├── page.tsx                 # Homepage
│   │   ├── products/
│   │   │   ├── page.tsx             # Product listing
│   │   │   └── [slug]/
│   │   │       └── page.tsx         # Product detail
│   │   ├── categories/
│   │   │   └── [slug]/
│   │   │       └── page.tsx         # Category page
│   │   ├── search/
│   │   │   └── page.tsx             # Search results
│   │   └── cart/
│   │       └── page.tsx             # Shopping cart
│   │
│   ├── (checkout)/                  # Checkout layout group
│   │   ├── checkout/
│   │   │   └── page.tsx             # Checkout flow
│   │   └── order-complete/
│   │       └── [orderId]/
│   │           └── page.tsx         # Order confirmation
│   │
│   ├── (account)/                   # Account layout group
│   │   ├── account/
│   │   │   ├── page.tsx             # Account dashboard
│   │   │   ├── orders/
│   │   │   │   ├── page.tsx         # Order history
│   │   │   │   └── [orderId]/
│   │   │   │       └── page.tsx     # Order detail
│   │   │   ├── addresses/
│   │   │   │   └── page.tsx         # Address book
│   │   │   └── profile/
│   │   │       └── page.tsx         # Profile settings
│   │   └── wishlist/
│   │       └── page.tsx             # Wishlist
│   │
│   ├── (auth)/                      # Auth layout group
│   │   ├── login/
│   │   │   └── page.tsx             # Login page
│   │   ├── register/
│   │   │   └── page.tsx             # Registration
│   │   └── forgot-password/
│   │       └── page.tsx             # Password reset
│   │
│   ├── (info)/                      # Info pages layout
│   │   ├── about/
│   │   │   └── page.tsx             # About us
│   │   ├── contact/
│   │   │   └── page.tsx             # Contact page
│   │   ├── faq/
│   │   │   └── page.tsx             # FAQ
│   │   └── [slug]/
│   │       └── page.tsx             # Dynamic info pages
│   │
│   ├── layout.tsx                   # Root layout
│   ├── not-found.tsx                # 404 page
│   └── error.tsx                    # Error boundary
│
├── components/
│   ├── layout/
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   ├── Navigation.tsx
│   │   ├── MobileMenu.tsx
│   │   ├── SearchBar.tsx
│   │   └── CartIcon.tsx
│   │
│   ├── product/
│   │   ├── ProductCard.tsx
│   │   ├── ProductGrid.tsx
│   │   ├── ProductGallery.tsx
│   │   ├── ProductInfo.tsx
│   │   ├── ProductVariants.tsx
│   │   ├── ProductPrice.tsx
│   │   ├── AddToCartButton.tsx
│   │   ├── QuantitySelector.tsx
│   │   └── StockIndicator.tsx
│   │
│   ├── cart/
│   │   ├── CartDrawer.tsx
│   │   ├── CartItem.tsx
│   │   ├── CartSummary.tsx
│   │   └── CartEmpty.tsx
│   │
│   ├── checkout/
│   │   ├── CheckoutForm.tsx
│   │   ├── ShippingForm.tsx
│   │   ├── PaymentForm.tsx
│   │   ├── OrderSummary.tsx
│   │   └── CheckoutSteps.tsx
│   │
│   ├── account/
│   │   ├── OrderCard.tsx
│   │   ├── AddressCard.tsx
│   │   └── ProfileForm.tsx
│   │
│   ├── ui/                          # shadcn components
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   ├── select.tsx
│   │   ├── dialog.tsx
│   │   ├── sheet.tsx
│   │   ├── skeleton.tsx
│   │   └── ...
│   │
│   └── common/
│       ├── Breadcrumb.tsx
│       ├── Pagination.tsx
│       ├── Rating.tsx
│       ├── Badge.tsx
│       ├── LoadingSpinner.tsx
│       └── EmptyState.tsx
│
├── lib/
│   ├── api/
│   │   ├── client.ts                # API client setup
│   │   ├── auth.ts                  # Auth API calls
│   │   ├── catalog.ts               # Product API calls
│   │   ├── cart.ts                  # Cart API calls
│   │   ├── order.ts                 # Order API calls
│   │   └── customer.ts              # Customer API calls
│   │
│   ├── hooks/
│   │   ├── useCart.ts
│   │   ├── useAuth.ts
│   │   ├── useProducts.ts
│   │   ├── useSearch.ts
│   │   └── useWishlist.ts
│   │
│   ├── stores/
│   │   ├── cartStore.ts
│   │   ├── authStore.ts
│   │   └── uiStore.ts
│   │
│   ├── utils/
│   │   ├── formatters.ts
│   │   ├── validators.ts
│   │   └── helpers.ts
│   │
│   └── types/
│       ├── product.ts
│       ├── cart.ts
│       ├── order.ts
│       ├── customer.ts
│       └── api.ts
│
├── public/
│   ├── images/
│   └── fonts/
│
├── styles/
│   └── globals.css
│
├── next.config.js
├── tailwind.config.js
├── tsconfig.json
├── package.json
└── Dockerfile
```

### Detailed Page Specifications

#### 1. Homepage (`/`)

**Purpose:** Landing page, featured products, promotions

**Components Required:**
- HeroBanner (promotional slider)
- FeaturedCategories
- ProductGrid (featured/new arrivals)
- PromoBanner
- Newsletter signup

**API Calls:**
```typescript
GET /api/v1/catalog/products?featured=true&limit=12
GET /api/v1/catalog/categories?featured=true
GET /api/v1/catalog/banners?placement=homepage
```

**Data Fetching:** Server-side (SSR) for SEO

---

#### 2. Product Listing (`/products`, `/categories/[slug]`)

**Purpose:** Browse products with filters

**Components Required:**
- ProductGrid
- FilterSidebar (price, size, color, category)
- SortDropdown
- Pagination
- ActiveFilters

**API Calls:**
```typescript
GET /api/v1/catalog/products?category={slug}&page={n}&limit=24&sort={field}&filters={json}
GET /api/v1/catalog/categories/{slug}
GET /api/v1/catalog/filters?category={slug}
```

**Data Fetching:** Server-side with client-side filter updates

**URL Structure:**
```
/products?page=1&sort=newest&price=100-500&size=M,L
/categories/baju-kurung?page=1&sort=popular
```

---

#### 3. Product Detail (`/products/[slug]`)

**Purpose:** Full product information, add to cart

**Components Required:**
- ProductGallery (image zoom, thumbnails)
- ProductInfo (title, price, description)
- ProductVariants (size, color selector)
- QuantitySelector
- AddToCartButton
- StockIndicator
- ProductTabs (description, specs, reviews)
- RelatedProducts

**API Calls:**
```typescript
GET /api/v1/catalog/products/{slug}
GET /api/v1/catalog/products/{slug}/variants
GET /api/v1/inventory/stock?productId={id}&variantIds={ids}
GET /api/v1/catalog/products/{slug}/related?limit=8
```

**Data Fetching:** 
- Product data: SSR (SEO)
- Stock levels: Client-side (real-time)
- Related products: Client-side

**Special Features:**
- Real-time stock checking
- Variant selection updates price/stock
- Image gallery with zoom

---

#### 4. Shopping Cart (`/cart`)

**Purpose:** Review cart, update quantities

**Components Required:**
- CartItemList
- CartItem (product info, quantity, remove)
- CartSummary (subtotal, shipping estimate, total)
- CouponInput
- ProceedToCheckout button
- CartEmpty state

**API Calls:**
```typescript
GET /api/v1/cart
PUT /api/v1/cart/items/{itemId}  # Update quantity
DELETE /api/v1/cart/items/{itemId}
POST /api/v1/cart/coupon  # Apply coupon
DELETE /api/v1/cart/coupon
```

**State Management:** Zustand cart store + API sync

**Special Features:**
- Optimistic updates
- Stock validation before checkout
- Persistent cart (localStorage + API sync when logged in)

---

#### 5. Checkout (`/checkout`)

**Purpose:** Complete purchase

**Components Required:**
- CheckoutSteps (shipping → payment → review)
- ShippingAddressForm
- ShippingMethodSelector
- PaymentMethodSelector
- OrderReview
- PlaceOrderButton

**API Calls:**
```typescript
GET /api/v1/cart/checkout  # Get checkout data
POST /api/v1/customer/addresses  # Save new address
GET /api/v1/shipping/methods?cartId={id}&address={json}
POST /api/v1/order/create
POST /api/v1/payment/process
```

**Data Fetching:** Client-side (protected route)

**Checkout Flow:**
```
1. Login/Guest checkout
2. Shipping address (select existing or add new)
3. Shipping method selection
4. Payment method
5. Review order
6. Place order → Payment processing
7. Redirect to confirmation
```

---

#### 6. Order Confirmation (`/order-complete/[orderId]`)

**Purpose:** Order success page

**Components Required:**
- OrderConfirmation
- OrderDetails
- PaymentStatus
- NextSteps
- ContinueShopping

**API Calls:**
```typescript
GET /api/v1/order/{orderId}/confirmation
```

---

#### 7. Search Results (`/search`)

**Purpose:** Product search

**Components Required:**
- SearchInput
- SearchFilters
- ProductGrid
- SearchSuggestions
- NoResults state

**API Calls:**
```typescript
GET /api/v1/search?q={query}&page={n}&filters={json}
GET /api/v1/search/suggestions?q={partial}
```

**Special Features:**
- Instant search suggestions (debounced)
- Search history (localStorage)
- Meilisearch integration for fast results

---

#### 8. Account Dashboard (`/account`)

**Purpose:** Customer account overview

**Components Required:**
- AccountSidebar
- RecentOrders
- AccountOverview
- QuickLinks

**API Calls:**
```typescript
GET /api/v1/customer/profile
GET /api/v1/order?limit=5
```

---

#### 9. Order History (`/account/orders`)

**Purpose:** View all orders

**Components Required:**
- OrderList
- OrderCard
- OrderStatusBadge
- Pagination

**API Calls:**
```typescript
GET /api/v1/order?page={n}&limit=10
```

---

#### 10. Order Detail (`/account/orders/[orderId]`)

**Purpose:** Full order information

**Components Required:**
- OrderHeader (status, date, order number)
- OrderItems
- OrderTimeline (tracking)
- ShippingInfo
- PaymentInfo
- OrderActions (reorder, cancel if applicable)

**API Calls:**
```typescript
GET /api/v1/order/{orderId}
GET /api/v1/order/{orderId}/tracking
```

---

#### 11. Auth Pages (`/login`, `/register`, `/forgot-password`)

**Purpose:** Authentication

**Components Required:**
- LoginForm
- RegisterForm
- ForgotPasswordForm
- SocialLoginButtons (optional)

**API Calls:**
```typescript
POST /api/v1/auth/login
POST /api/v1/auth/register
POST /api/v1/auth/forgot-password
POST /api/v1/auth/reset-password
POST /api/v1/auth/refresh
```

**Special Features:**
- Form validation (Zod)
- Remember me functionality
- Redirect after login
- Password strength indicator

---

## API Endpoints Required

### Service: Auth (service-auth)

```
POST   /api/v1/auth/register           # User registration
POST   /api/v1/auth/login              # User login
POST   /api/v1/auth/logout             # User logout
POST   /api/v1/auth/refresh            # Refresh token
POST   /api/v1/auth/forgot-password    # Request password reset
POST   /api/v1/auth/reset-password     # Reset password
GET    /api/v1/auth/me                 # Get current user
PUT    /api/v1/auth/me                 # Update current user
POST   /api/v1/auth/change-password    # Change password
```

### Service: Catalog (service-catalog)

```
# Products
GET    /api/v1/catalog/products                    # List products
GET    /api/v1/catalog/products/:slug              # Get product by slug
GET    /api/v1/catalog/products/:slug/variants     # Get product variants
GET    /api/v1/catalog/products/:slug/related      # Get related products

# Categories
GET    /api/v1/catalog/categories                  # List categories
GET    /api/v1/catalog/categories/:slug            # Get category
GET    /api/v1/catalog/categories/:slug/products   # Get products in category

# Filters
GET    /api/v1/catalog/filters                     # Get available filters
GET    /api/v1/catalog/filters/:category           # Get filters for category

# Banners/Promotions
GET    /api/v1/catalog/banners                     # Get banners

# Search (proxies to Meilisearch)
GET    /api/v1/search                              # Search products
GET    /api/v1/search/suggestions                  # Search suggestions
```

### Service: Inventory (service-inventory)

```
# Stock checking (public)
GET    /api/v1/inventory/stock                     # Check stock levels
GET    /api/v1/inventory/stock/:productId          # Stock for product

# Warehouses (admin only)
GET    /api/v1/inventory/warehouses                # List warehouses
POST   /api/v1/inventory/warehouses                # Create warehouse
GET    /api/v1/inventory/warehouses/:id            # Get warehouse
PUT    /api/v1/inventory/warehouses/:id            # Update warehouse

# Stock movements (admin only)
GET    /api/v1/inventory/movements                 # List movements
POST   /api/v1/inventory/movements                 # Create movement
POST   /api/v1/inventory/transfer                  # Stock transfer
```

### Service: Order (service-order)

```
# Cart
GET    /api/v1/cart                                # Get cart
POST   /api/v1/cart/items                          # Add to cart
PUT    /api/v1/cart/items/:itemId                  # Update cart item
DELETE /api/v1/cart/items/:itemId                  # Remove from cart
DELETE /api/v1/cart                                # Clear cart
POST   /api/v1/cart/coupon                         # Apply coupon
DELETE /api/v1/cart/coupon                         # Remove coupon
GET    /api/v1/cart/checkout                       # Get checkout data

# Orders
GET    /api/v1/order                               # List user orders
POST   /api/v1/order                               # Create order
GET    /api/v1/order/:id                           # Get order
GET    /api/v1/order/:id/confirmation              # Order confirmation
GET    /api/v1/order/:id/tracking                  # Order tracking
POST   /api/v1/order/:id/cancel                    # Cancel order

# Shipping
GET    /api/v1/shipping/methods                    # Get shipping methods

# Payment
POST   /api/v1/payment/process                     # Process payment
POST   /api/v1/payment/webhook                     # Payment webhook
```

### Service: Customer (service-customer)

```
GET    /api/v1/customer/profile                    # Get profile
PUT    /api/v1/customer/profile                    # Update profile

# Addresses
GET    /api/v1/customer/addresses                  # List addresses
POST   /api/v1/customer/addresses                  # Add address
PUT    /api/v1/customer/addresses/:id              # Update address
DELETE /api/v1/customer/addresses/:id              # Delete address
PUT    /api/v1/customer/addresses/:id/default      # Set default

# Wishlist
GET    /api/v1/customer/wishlist                   # Get wishlist
POST   /api/v1/customer/wishlist                   # Add to wishlist
DELETE /api/v1/customer/wishlist/:productId        # Remove from wishlist
```

---

## Database Schema

### Schema: auth

```sql
-- Users table
CREATE TABLE auth.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    email_verified_at TIMESTAMP,
    status VARCHAR(20) DEFAULT 'active', -- active, inactive, suspended
    role VARCHAR(20) DEFAULT 'customer', -- customer, admin, agent, warehouse
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Sessions/Refresh tokens
CREATE TABLE auth.sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    refresh_token VARCHAR(255) UNIQUE NOT NULL,
    user_agent TEXT,
    ip_address INET,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Password resets
CREATE TABLE auth.password_resets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    token VARCHAR(255) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_users_email ON auth.users(email);
CREATE INDEX idx_sessions_user_id ON auth.sessions(user_id);
CREATE INDEX idx_sessions_refresh_token ON auth.sessions(refresh_token);
```

### Schema: catalog

```sql
-- Categories
CREATE TABLE catalog.categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_id UUID REFERENCES catalog.categories(id),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 0,
    meta_title VARCHAR(255),
    meta_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products
CREATE TABLE catalog.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    description TEXT,
    short_description VARCHAR(500),
    base_price DECIMAL(12,2) NOT NULL,
    compare_price DECIMAL(12,2), -- original price for discounts
    cost_price DECIMAL(12,2),
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    has_variants BOOLEAN DEFAULT false,
    weight DECIMAL(10,3), -- in kg
    meta_title VARCHAR(255),
    meta_description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product Categories (many-to-many)
CREATE TABLE catalog.product_categories (
    product_id UUID REFERENCES catalog.products(id) ON DELETE CASCADE,
    category_id UUID REFERENCES catalog.categories(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, category_id)
);

-- Product Images
CREATE TABLE catalog.product_images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES catalog.products(id) ON DELETE CASCADE,
    url VARCHAR(500) NOT NULL,
    alt_text VARCHAR(255),
    sort_order INT DEFAULT 0,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product Attributes (for filtering - e.g., material, style)
CREATE TABLE catalog.attributes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    type VARCHAR(20) DEFAULT 'select', -- select, multiselect, text
    is_filterable BOOLEAN DEFAULT true,
    sort_order INT DEFAULT 0
);

-- Attribute Values
CREATE TABLE catalog.attribute_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attribute_id UUID REFERENCES catalog.attributes(id) ON DELETE CASCADE,
    value VARCHAR(255) NOT NULL,
    sort_order INT DEFAULT 0
);

-- Product Attribute Values
CREATE TABLE catalog.product_attributes (
    product_id UUID REFERENCES catalog.products(id) ON DELETE CASCADE,
    attribute_id UUID REFERENCES catalog.attributes(id) ON DELETE CASCADE,
    attribute_value_id UUID REFERENCES catalog.attribute_values(id),
    PRIMARY KEY (product_id, attribute_id)
);

-- Product Variants (combinations of options like size + color)
CREATE TABLE catalog.product_variants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id UUID REFERENCES catalog.products(id) ON DELETE CASCADE,
    sku VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255), -- e.g., "S / Red"
    price DECIMAL(12,2), -- NULL = use product base_price
    compare_price DECIMAL(12,2),
    weight DECIMAL(10,3),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Variant Options (Size, Color, etc.)
CREATE TABLE catalog.variant_options (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL, -- "Size", "Color"
    sort_order INT DEFAULT 0
);

-- Variant Option Values
CREATE TABLE catalog.variant_option_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    option_id UUID REFERENCES catalog.variant_options(id) ON DELETE CASCADE,
    value VARCHAR(100) NOT NULL, -- "S", "M", "L", "Red", "Blue"
    sort_order INT DEFAULT 0
);

-- Product Variant Option Values (which options make up a variant)
CREATE TABLE catalog.product_variant_options (
    variant_id UUID REFERENCES catalog.product_variants(id) ON DELETE CASCADE,
    option_id UUID REFERENCES catalog.variant_options(id),
    option_value_id UUID REFERENCES catalog.variant_option_values(id),
    PRIMARY KEY (variant_id, option_id)
);

-- Indexes
CREATE INDEX idx_products_slug ON catalog.products(slug);
CREATE INDEX idx_products_sku ON catalog.products(sku);
CREATE INDEX idx_products_is_active ON catalog.products(is_active);
CREATE INDEX idx_categories_slug ON catalog.categories(slug);
CREATE INDEX idx_product_variants_sku ON catalog.product_variants(sku);
```

### Schema: inventory

```sql
-- Warehouses / Branches
CREATE TABLE inventory.warehouses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(20) DEFAULT 'warehouse', -- warehouse, store, virtual
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    postcode VARCHAR(20),
    country VARCHAR(2) DEFAULT 'MY',
    phone VARCHAR(20),
    email VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    is_pickup_location BOOLEAN DEFAULT false,
    priority INT DEFAULT 0, -- for stock allocation
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Stock Items
CREATE TABLE inventory.stock_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID REFERENCES inventory.warehouses(id) ON DELETE CASCADE,
    product_id UUID NOT NULL, -- References catalog.products
    variant_id UUID, -- References catalog.product_variants (NULL for non-variant products)
    quantity INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0, -- Reserved for pending orders
    reorder_point INT DEFAULT 10,
    reorder_quantity INT DEFAULT 50,
    bin_location VARCHAR(50), -- Warehouse bin/shelf location
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(warehouse_id, product_id, variant_id)
);

-- Stock Movements
CREATE TABLE inventory.stock_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    warehouse_id UUID REFERENCES inventory.warehouses(id),
    product_id UUID NOT NULL,
    variant_id UUID,
    type VARCHAR(20) NOT NULL, -- receive, sale, adjustment, transfer_in, transfer_out, return
    quantity INT NOT NULL, -- positive or negative
    reference_type VARCHAR(50), -- order, transfer, adjustment
    reference_id UUID, -- ID of related order/transfer
    notes TEXT,
    created_by UUID, -- User who created movement
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Stock Transfers
CREATE TABLE inventory.stock_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_number VARCHAR(50) UNIQUE NOT NULL,
    from_warehouse_id UUID REFERENCES inventory.warehouses(id),
    to_warehouse_id UUID REFERENCES inventory.warehouses(id),
    status VARCHAR(20) DEFAULT 'pending', -- pending, in_transit, completed, cancelled
    notes TEXT,
    created_by UUID,
    approved_by UUID,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transfer Items
CREATE TABLE inventory.stock_transfer_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_id UUID REFERENCES inventory.stock_transfers(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,
    variant_id UUID,
    quantity INT NOT NULL,
    received_quantity INT DEFAULT 0
);

-- Indexes
CREATE INDEX idx_stock_items_warehouse ON inventory.stock_items(warehouse_id);
CREATE INDEX idx_stock_items_product ON inventory.stock_items(product_id);
CREATE INDEX idx_stock_movements_warehouse ON inventory.stock_movements(warehouse_id);
CREATE INDEX idx_stock_movements_type ON inventory.stock_movements(type);
CREATE INDEX idx_stock_movements_created ON inventory.stock_movements(created_at);
```

### Schema: sales

```sql
-- Carts
CREATE TABLE sales.carts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID, -- NULL for guest carts
    session_id VARCHAR(255), -- For guest identification
    coupon_code VARCHAR(50),
    coupon_discount DECIMAL(12,2) DEFAULT 0,
    notes TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cart Items
CREATE TABLE sales.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cart_id UUID REFERENCES sales.carts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,
    variant_id UUID,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Orders
CREATE TABLE sales.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID,
    agent_id UUID, -- If order placed by agent
    status VARCHAR(30) DEFAULT 'pending', 
    -- pending, confirmed, processing, shipped, delivered, cancelled, refunded
    
    -- Pricing
    subtotal DECIMAL(12,2) NOT NULL,
    shipping_cost DECIMAL(12,2) DEFAULT 0,
    tax_amount DECIMAL(12,2) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    total DECIMAL(12,2) NOT NULL,
    
    -- Coupon
    coupon_code VARCHAR(50),
    coupon_discount DECIMAL(12,2) DEFAULT 0,
    
    -- Shipping
    shipping_method VARCHAR(50),
    shipping_address JSONB NOT NULL,
    -- {name, phone, address1, address2, city, state, postcode, country}
    
    -- Billing
    billing_address JSONB,
    
    -- Fulfillment
    warehouse_id UUID, -- Fulfilling warehouse
    tracking_number VARCHAR(100),
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP,
    
    -- Notes
    customer_notes TEXT,
    admin_notes TEXT,
    
    -- Timestamps
    confirmed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order Items
CREATE TABLE sales.order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES sales.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,
    variant_id UUID,
    sku VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    variant_name VARCHAR(255),
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    total_price DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Order Status History
CREATE TABLE sales.order_status_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES sales.orders(id) ON DELETE CASCADE,
    status VARCHAR(30) NOT NULL,
    notes TEXT,
    created_by UUID,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments
CREATE TABLE sales.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES sales.orders(id) ON DELETE CASCADE,
    payment_method VARCHAR(50) NOT NULL, -- fpx, card, cod, bank_transfer
    payment_provider VARCHAR(50), -- stripe, billplz, senangpay
    transaction_id VARCHAR(255),
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, completed, failed, refunded
    paid_at TIMESTAMP,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Coupons
CREATE TABLE sales.coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL, -- percentage, fixed
    value DECIMAL(12,2) NOT NULL,
    min_order_amount DECIMAL(12,2) DEFAULT 0,
    max_discount DECIMAL(12,2), -- Max discount for percentage type
    usage_limit INT,
    used_count INT DEFAULT 0,
    per_customer_limit INT DEFAULT 1,
    starts_at TIMESTAMP,
    expires_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX idx_orders_user_id ON sales.orders(user_id);
CREATE INDEX idx_orders_status ON sales.orders(status);
CREATE INDEX idx_orders_order_number ON sales.orders(order_number);
CREATE INDEX idx_orders_created ON sales.orders(created_at);
CREATE INDEX idx_carts_user_id ON sales.carts(user_id);
CREATE INDEX idx_carts_session_id ON sales.carts(session_id);
```

### Schema: crm (Customer)

```sql
-- Customer Profiles (extends auth.users)
CREATE TABLE crm.customer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    date_of_birth DATE,
    gender VARCHAR(10),
    customer_group VARCHAR(50) DEFAULT 'regular', -- regular, vip, wholesale
    total_orders INT DEFAULT 0,
    total_spent DECIMAL(12,2) DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Customer Addresses
CREATE TABLE crm.addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    label VARCHAR(50), -- Home, Office, etc.
    recipient_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    address_line1 VARCHAR(255) NOT NULL,
    address_line2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postcode VARCHAR(20) NOT NULL,
    country VARCHAR(2) DEFAULT 'MY',
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wishlists
CREATE TABLE crm.wishlists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    product_id UUID NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, product_id)
);

-- Indexes
CREATE INDEX idx_addresses_user_id ON crm.addresses(user_id);
CREATE INDEX idx_wishlists_user_id ON crm.wishlists(user_id);
```

---

## Infrastructure Setup

### VPS Requirements (Recommended)

#### Development/Staging
- 4 vCPU, 8GB RAM, 80GB SSD
- ~RM150-200/month (Hostinger, DigitalOcean, Vultr)

#### Production (Initial)
```
Node 1: Gateway + Frontends
- 4 vCPU, 8GB RAM, 50GB SSD
- Traefik, All Next.js apps

Node 2: Backend Services
- 4 vCPU, 16GB RAM, 50GB SSD
- All Go services

Node 3: Data Layer
- 4 vCPU, 16GB RAM, 200GB SSD
- PostgreSQL, Redis, Meilisearch, MinIO
```

Total: ~RM600-800/month

#### Production (Scaled)
Add more nodes as needed, or scale vertically.

---

### Docker Compose - Development

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  # ============ DATA LAYER ============
  postgres:
    image: postgres:16-alpine
    container_name: niaga-postgres
    environment:
      POSTGRES_USER: niaga
      POSTGRES_PASSWORD: niaga_dev_password
      POSTGRES_DB: niaga
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./infra-database/init:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U niaga"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: niaga-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes

  meilisearch:
    image: getmeili/meilisearch:v1.6
    container_name: niaga-meilisearch
    environment:
      MEILI_MASTER_KEY: niaga_meili_dev_key
      MEILI_ENV: development
    ports:
      - "7700:7700"
    volumes:
      - meilisearch_data:/meili_data

  minio:
    image: minio/minio:latest
    container_name: niaga-minio
    environment:
      MINIO_ROOT_USER: niaga_minio
      MINIO_ROOT_PASSWORD: niaga_minio_password
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data
    command: server /data --console-address ":9001"

  nats:
    image: nats:2.10-alpine
    container_name: niaga-nats
    ports:
      - "4222:4222"
      - "8222:8222"
    command: "--jetstream --store_dir /data"
    volumes:
      - nats_data:/data

  # ============ BACKEND SERVICES ============
  service-auth:
    build:
      context: ./service-auth
      dockerfile: Dockerfile.dev
    container_name: niaga-auth
    ports:
      - "8001:8001"
    environment:
      - DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=dev_jwt_secret_change_in_production
      - NATS_URL=nats://nats:4222
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    volumes:
      - ./service-auth:/app

  service-catalog:
    build:
      context: ./service-catalog
      dockerfile: Dockerfile.dev
    container_name: niaga-catalog
    ports:
      - "8002:8002"
    environment:
      - DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
      - REDIS_URL=redis://redis:6379
      - MEILISEARCH_URL=http://meilisearch:7700
      - MEILISEARCH_KEY=niaga_meili_dev_key
      - MINIO_ENDPOINT=minio:9000
      - MINIO_ACCESS_KEY=niaga_minio
      - MINIO_SECRET_KEY=niaga_minio_password
      - NATS_URL=nats://nats:4222
    depends_on:
      - postgres
      - redis
      - meilisearch
      - minio
    volumes:
      - ./service-catalog:/app

  service-inventory:
    build:
      context: ./service-inventory
      dockerfile: Dockerfile.dev
    container_name: niaga-inventory
    ports:
      - "8003:8003"
    environment:
      - DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
      - REDIS_URL=redis://redis:6379
      - NATS_URL=nats://nats:4222
    depends_on:
      - postgres
      - redis
      - nats
    volumes:
      - ./service-inventory:/app

  service-order:
    build:
      context: ./service-order
      dockerfile: Dockerfile.dev
    container_name: niaga-order
    ports:
      - "8004:8004"
    environment:
      - DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
      - REDIS_URL=redis://redis:6379
      - NATS_URL=nats://nats:4222
      - AUTH_SERVICE_URL=http://service-auth:8001
      - INVENTORY_SERVICE_URL=http://service-inventory:8003
    depends_on:
      - postgres
      - redis
      - nats
    volumes:
      - ./service-order:/app

  service-customer:
    build:
      context: ./service-customer
      dockerfile: Dockerfile.dev
    container_name: niaga-customer
    ports:
      - "8005:8005"
    environment:
      - DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
      - REDIS_URL=redis://redis:6379
      - NATS_URL=nats://nats:4222
    depends_on:
      - postgres
      - redis
    volumes:
      - ./service-customer:/app

  # ============ FRONTEND ============
  frontend-storefront:
    build:
      context: ./frontend-storefront
      dockerfile: Dockerfile.dev
    container_name: niaga-storefront
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://localhost:8080/api
    volumes:
      - ./frontend-storefront:/app
      - /app/node_modules
      - /app/.next

  # ============ API GATEWAY ============
  traefik:
    image: traefik:v3.0
    container_name: niaga-gateway
    ports:
      - "8080:80"
      - "8443:443"
      - "8081:8080" # Dashboard
    volumes:
      - ./infra-platform/traefik/traefik.dev.yml:/etc/traefik/traefik.yml
      - ./infra-platform/traefik/dynamic:/etc/traefik/dynamic
      - /var/run/docker.sock:/var/run/docker.sock:ro

volumes:
  postgres_data:
  redis_data:
  meilisearch_data:
  minio_data:
  nats_data:
```

---

### Traefik Configuration

```yaml
# infra-platform/traefik/traefik.dev.yml
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"

providers:
  file:
    directory: /etc/traefik/dynamic
    watch: true

log:
  level: DEBUG
```

```yaml
# infra-platform/traefik/dynamic/routes.yml
http:
  routers:
    # API Routes
    auth-router:
      rule: "PathPrefix(`/api/v1/auth`)"
      service: auth-service
      entryPoints:
        - web

    catalog-router:
      rule: "PathPrefix(`/api/v1/catalog`) || PathPrefix(`/api/v1/search`)"
      service: catalog-service
      entryPoints:
        - web

    inventory-router:
      rule: "PathPrefix(`/api/v1/inventory`)"
      service: inventory-service
      entryPoints:
        - web

    order-router:
      rule: "PathPrefix(`/api/v1/cart`) || PathPrefix(`/api/v1/order`) || PathPrefix(`/api/v1/shipping`) || PathPrefix(`/api/v1/payment`)"
      service: order-service
      entryPoints:
        - web

    customer-router:
      rule: "PathPrefix(`/api/v1/customer`)"
      service: customer-service
      entryPoints:
        - web

    # Frontend
    storefront-router:
      rule: "PathPrefix(`/`)"
      service: storefront-service
      entryPoints:
        - web
      priority: 1

  services:
    auth-service:
      loadBalancer:
        servers:
          - url: "http://service-auth:8001"

    catalog-service:
      loadBalancer:
        servers:
          - url: "http://service-catalog:8002"

    inventory-service:
      loadBalancer:
        servers:
          - url: "http://service-inventory:8003"

    order-service:
      loadBalancer:
        servers:
          - url: "http://service-order:8004"

    customer-service:
      loadBalancer:
        servers:
          - url: "http://service-customer:8005"

    storefront-service:
      loadBalancer:
        servers:
          - url: "http://frontend-storefront:3000"
```

---

## Development Workflow

### Initial Setup

```bash
# 1. Clone all repositories
mkdir niaga-platform && cd niaga-platform

git clone git@github.com:your-org/infra-platform.git
git clone git@github.com:your-org/infra-database.git
git clone git@github.com:your-org/service-auth.git
git clone git@github.com:your-org/service-catalog.git
git clone git@github.com:your-org/service-inventory.git
git clone git@github.com:your-org/service-order.git
git clone git@github.com:your-org/service-customer.git
git clone git@github.com:your-org/frontend-storefront.git

# 2. Start infrastructure
docker-compose -f docker-compose.dev.yml up -d postgres redis meilisearch minio nats

# 3. Run database migrations
cd infra-database
./scripts/migrate.sh up

# 4. Start services (in separate terminals or use docker-compose)
docker-compose -f docker-compose.dev.yml up service-auth service-catalog service-inventory service-order service-customer

# 5. Start frontend
docker-compose -f docker-compose.dev.yml up frontend-storefront

# 6. Start gateway
docker-compose -f docker-compose.dev.yml up traefik
```

### Daily Development

```bash
# Start all dependencies
docker-compose -f docker-compose.dev.yml up -d

# Work on specific service
cd service-catalog
go run cmd/server/main.go

# Work on frontend
cd frontend-storefront
npm run dev

# Run tests
go test ./...
npm run test
```

---

## Phase 1 Implementation Checklist

### Week 1-2: Infrastructure Setup

- [ ] Setup VPS (staging environment)
- [ ] Install Docker & Docker Compose
- [ ] Setup private Git repositories (GitHub/Gitea)
- [ ] Create infra-platform repo with Docker configs
- [ ] Create infra-database repo with initial migrations
- [ ] Deploy PostgreSQL, Redis, Meilisearch, MinIO, NATS
- [ ] Configure Traefik with SSL (Let's Encrypt)
- [ ] Setup basic CI/CD pipeline

### Week 3-4: Auth Service

- [ ] Create service-auth repo
- [ ] Implement user registration
- [ ] Implement login/logout
- [ ] Implement JWT token refresh
- [ ] Implement password reset
- [ ] Add rate limiting
- [ ] Write unit tests
- [ ] Deploy to staging

### Week 5-6: Catalog Service

- [ ] Create service-catalog repo
- [ ] Implement category CRUD
- [ ] Implement product CRUD
- [ ] Implement product variants
- [ ] Implement product images (MinIO upload)
- [ ] Setup Meilisearch indexing
- [ ] Implement search & filters
- [ ] Write unit tests
- [ ] Deploy to staging

### Week 7-8: Inventory Service (Basic)

- [ ] Create service-inventory repo
- [ ] Implement warehouse management
- [ ] Implement stock items CRUD
- [ ] Implement stock checking API (public)
- [ ] Write unit tests
- [ ] Deploy to staging

### Week 9-10: Frontend Storefront (Core)

- [ ] Create frontend-storefront repo
- [ ] Setup Next.js 14 with TypeScript
- [ ] Install & configure Tailwind + shadcn/ui
- [ ] Implement layout (header, footer, navigation)
- [ ] Implement homepage
- [ ] Implement product listing page
- [ ] Implement product detail page
- [ ] Implement search functionality
- [ ] Deploy to staging

### Week 11-12: Cart & Checkout

- [ ] Create service-order repo (cart functionality)
- [ ] Implement cart API
- [ ] Implement cart UI (drawer + page)
- [ ] Implement checkout flow UI
- [ ] Implement order creation
- [ ] Basic payment integration (test mode)
- [ ] Order confirmation page
- [ ] Deploy to staging

### Week 13-14: Customer Features

- [ ] Create service-customer repo
- [ ] Implement customer profile
- [ ] Implement address management
- [ ] Implement auth pages (login, register)
- [ ] Implement account dashboard
- [ ] Implement order history
- [ ] Deploy to staging

### Week 15-16: Testing & Polish

- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] SEO optimization
- [ ] Mobile responsiveness review
- [ ] Security audit
- [ ] Bug fixes
- [ ] Documentation

### Week 17-18: Production Deployment

- [ ] Setup production VPS cluster
- [ ] Configure production databases
- [ ] Setup monitoring (Grafana + Prometheus)
- [ ] Setup log aggregation (Loki)
- [ ] Configure backups
- [ ] Deploy all services
- [ ] DNS & SSL setup
- [ ] Go live!

---

## Quick Reference Commands

```bash
# Database migrations
cd infra-database && ./scripts/migrate.sh up
cd infra-database && ./scripts/migrate.sh down 1
cd infra-database && ./scripts/migrate.sh create add_new_table

# Docker operations
docker-compose -f docker-compose.dev.yml up -d          # Start all
docker-compose -f docker-compose.dev.yml down           # Stop all
docker-compose -f docker-compose.dev.yml logs -f        # View logs
docker-compose -f docker-compose.dev.yml restart <svc>  # Restart service

# Go service development
go run cmd/server/main.go          # Run service
go build -o bin/server cmd/server/main.go  # Build
go test ./...                      # Run tests
go test -cover ./...               # Test with coverage

# Next.js development
npm run dev                        # Development server
npm run build                      # Production build
npm run start                      # Start production
npm run lint                       # Lint code
npm run test                       # Run tests

# Database access
docker exec -it niaga-postgres psql -U niaga -d niaga

# Redis access
docker exec -it niaga-redis redis-cli
```

---

## Notes

- Semua API endpoints prefix dengan `/api/v1/` untuk versioning
- Setiap service ada healthcheck endpoint di `/health`
- JWT tokens expire dalam 15 minit, refresh token valid 7 hari
- Semua prices stored dalam sen (multiply by 100) untuk avoid floating point issues
- Images di-resize ke multiple sizes (thumbnail, medium, large) bila upload
- Search index update secara async via NATS events
