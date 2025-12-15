# Fashion eCommerce Platform - Critical Feature Set & Architecture

> Product Architecture Document for Kilang Desa Murni Batik
>
> Version: 1.0.0 | Last Updated: 2024-12-15

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Storefront Features](#1-storefront-features-the-fashion-experience)
3. [Admin Panel Features](#2-admin-panel-features-operations--merchandising)
4. [Microservice Boundaries](#3-microservice-boundaries-architecture)
5. [Data Model](#4-data-model)
6. [Implementation Recommendations](#5-implementation-recommendations)

---

## Executive Summary

This document defines the critical feature set for the **Kilang Desa Murni Batik** fashion eCommerce platform, covering both the **Storefront** (customer-facing) and **Admin Panel** (back-office) applications.

### Key Challenges Addressed

| Challenge | Solution Approach |
|-----------|-------------------|
| Complex product variants (Size/Color matrices) | Parent-Child SKU model in Catalog Service |
| Seasonal collections | Collections with scheduled publishing |
| High-volume flash sales | Redis-based atomic stock deduction, purchase limits |
| Real-time stock visibility | Per-variant inventory with WebSocket updates |

### Target Market

- **B2C Fashion Retail**: Malaysian batik products (clothing, fabrics, accessories)
- **Product Types**: Kain (fabric by meter), Baju Siap (ready-to-wear), Aksesori, Set Lengkap

---

## 1. STOREFRONT FEATURES (The "Fashion" Experience)

### 1.1 Product Discovery & Search

| Feature | Description | Fashion-Specific Requirements |
|---------|-------------|-------------------------------|
| **Faceted Search** | Multi-dimensional filtering | Size, Color, Material, Fabric Width, Pattern Style, Price Range, Collection |
| **Size Guide Integration** | Interactive sizing tool | Body measurements → Recommended size, Fabric shrinkage calculator |
| **Visual Search** | Image-based product discovery | "Find similar batik patterns" |
| **Shop the Look** | Complete outfit suggestions | Cross-sell coordinated batik sets (baju + sampin + songkok) |
| **Recently Viewed** | Personalized history | Persisted across sessions |
| **Saved Searches** | Alert on new matches | "Notify me when Blue Songket Size M arrives" |

---

### 1.2 Product Detail Page (PDP) - Variant Handling

**The Critical Challenge**: Showing real-time availability across Size × Color matrix

```
┌─────────────────────────────────────────────────────────────────┐
│  BATIK SILK SARONG - RM 250                                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Color: [🔴 Red] [🔵 Blue ✓] [🟢 Green] [⚫ Black - Sold Out]  │
│                                                                 │
│  Size:  [ S ]  [ M - Low Stock ]  [ L ✓ ]  [ XL ]              │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ Availability Matrix (Real-time from Inventory Service)  │   │
│  │                                                         │   │
│  │         Red    Blue    Green   Black                    │   │
│  │   S     ✓ 12   ✓ 8     ✓ 5     ✗ 0                     │   │
│  │   M     ✓ 3    ✓ 15    ✗ 0     ✗ 0     ← Low Stock     │   │
│  │   L     ✓ 20   ✓ 18    ✓ 12    ✗ 0                     │   │
│  │   XL    ✓ 7    ✓ 9     ✓ 4     ✗ 0                     │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  📏 Size Guide | 📐 Fabric: 100% Silk | Width: 115cm           │
│                                                                 │
│  [  ADD TO CART  ]    [ ♡ Add to Wishlist ]                    │
│                                                                 │
│  🔔 Black out of stock? [Notify when available]                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### PDP Feature Requirements

| Feature | Implementation |
|---------|---------------|
| **Live Stock Matrix** | WebSocket or polling from Inventory Service |
| **Cross-Variant Navigation** | Selecting "Red" updates available sizes, price changes |
| **Back-in-Stock Alerts** | Customer Service stores notification preferences |
| **Size Recommendation** | Based on purchase history + body profile |
| **Fabric Calculator** | For "kain" products: meters needed for different garments |
| **Care Instructions** | Batik-specific washing/ironing guidance |
| **360° View / Zoom** | High-res image gallery with zoom capability |

---

### 1.3 User Account Features (Fashion-Specific)

| Feature | Description | Service |
|---------|-------------|---------|
| **Fit Profile** | Store body measurements, preferred fits | Customer Service |
| **Style Preferences** | Preferred patterns, colors, occasions | Customer Service |
| **Wishlist with Variants** | Save specific Size+Color combinations | Customer Service |
| **Order History with Reorder** | One-click reorder same variant | Order Service |
| **Returns Portal** | Self-service returns, reason tracking | Order Service |
| **Size History** | "You bought M in this brand before" | Customer Service |
| **Loyalty Points** | Points per purchase, tier benefits | Customer Service |

---

### 1.4 Fashion-Specific Storefront Pages

| Page | Features |
|------|----------|
| **Collections** | Seasonal (Raya 2024, Merdeka), Curated (Wedding, Casual) |
| **Lookbooks** | Editorial-style product presentations |
| **New Arrivals** | Time-based filtering, "This Week" badges |
| **Sale / Flash Sale** | Countdown timers, limited stock indicators |
| **Trending** | Based on views, purchases, social engagement |
| **Batik Guide** | Educational content (types, care, styling) |

---

## 2. ADMIN PANEL FEATURES (Operations & Merchandising)

### 2.1 Catalog Management - Parent/Child SKU Model

**The Challenge**: One T-shirt = 1 Parent Product, but 20 Child SKUs (5 colors × 4 sizes)

```
┌────────────────────────────────────────────────────────────────────┐
│  PARENT PRODUCT: Batik Silk Sarong                                 │
│  Master SKU: BSS-001                                               │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  VARIANTS (Child SKUs)                              [+ Add]  │ │
│  ├──────────────────────────────────────────────────────────────┤ │
│  │  SKU          │ Color  │ Size │ Price  │ Stock │ Status      │ │
│  ├──────────────────────────────────────────────────────────────┤ │
│  │  BSS-001-R-S  │ Red    │ S    │ RM 250 │ 12    │ ✓ Active   │ │
│  │  BSS-001-R-M  │ Red    │ M    │ RM 250 │ 3     │ ⚠️ Low     │ │
│  │  BSS-001-R-L  │ Red    │ L    │ RM 250 │ 20    │ ✓ Active   │ │
│  │  BSS-001-B-S  │ Blue   │ S    │ RM 250 │ 8     │ ✓ Active   │ │
│  │  BSS-001-B-M  │ Blue   │ M    │ RM 260 │ 15    │ ✓ Active   │ │
│  │  BSS-001-BK-M │ Black  │ M    │ RM 270 │ 0     │ ✗ OOS      │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  VARIANT OPTIONS:                                                  │
│  • Color: [Red, Blue, Green, Black]  ← Managed in Catalog Service │
│  • Size:  [S, M, L, XL, XXL]                                      │
│                                                                    │
│  [Generate All Combinations] [Bulk Edit Prices] [Import Variants] │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

#### Catalog Admin Features

| Feature | Description |
|---------|-------------|
| **Variant Matrix Builder** | Auto-generate all Size×Color combinations |
| **Bulk Variant Editor** | Update prices/status for multiple variants |
| **Variant-Level Pricing** | Different prices per variant (Black +RM 20) |
| **Variant Images** | Color-specific images (swatch → gallery) |
| **SKU Generator** | Auto-generate SKUs: `{PARENT}-{COLOR}-{SIZE}` |
| **Import/Export** | CSV bulk upload with variant support |
| **Product Duplication** | Clone product with all variants |
| **Attribute Templates** | Predefined options (Standard Sizes, Batik Colors) |

---

### 2.2 Inventory Management

#### Multi-Warehouse Stock View

```
┌────────────────────────────────────────────────────────────────────┐
│  INVENTORY DASHBOARD                                               │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌───────────┐ │
│  │ Total SKUs  │  │ Low Stock   │  │ Out of Stock│  │ Reserved  │ │
│  │    1,247    │  │     48      │  │     23      │  │    156    │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └───────────┘ │
│                                                                    │
│  STOCK BY WAREHOUSE:                                               │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  Warehouse          │ Available │ Reserved │ Incoming │ Total │ │
│  ├──────────────────────────────────────────────────────────────┤ │
│  │  🏭 Shah Alam HQ    │   2,450   │   120    │   500    │ 3,070 │ │
│  │  🏢 Kuala Terengganu│   1,200   │    36    │     0    │ 1,236 │ │
│  │  📦 Dropship Pool   │     450   │     0    │   200    │   650 │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  LOW STOCK ALERTS (Threshold-based):                              │
│  ⚠️ BSS-001-R-M (Red, M) - Only 3 left (threshold: 5)            │
│  ⚠️ BSK-002-BK-L (Black, L) - Only 2 left (threshold: 10)        │
│                                                                    │
│  [Create Transfer] [Adjust Stock] [Export Report]                 │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

#### Inventory Admin Features

| Feature | Description |
|---------|-------------|
| **Per-Variant Stock Tracking** | Stock at SKU level, not product level |
| **Multi-Warehouse Allocation** | Which warehouse fulfills which orders |
| **Stock Reservations** | Hold stock for cart items / pending orders |
| **Transfer Management** | Move stock between warehouses |
| **Receiving Module** | Record incoming shipments |
| **Low Stock Alerts** | Configurable thresholds per SKU |
| **Stock History** | Audit trail of all movements |
| **Inventory Valuation** | FIFO/LIFO cost tracking |

---

### 2.3 Campaign & Collection Management

#### For Seasonal Collections & Flash Sales

```
┌────────────────────────────────────────────────────────────────────┐
│  COLLECTIONS & CAMPAIGNS                                           │
├────────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ACTIVE COLLECTIONS:                                               │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  Collection         │ Products │ Status   │ Period           │ │
│  ├──────────────────────────────────────────────────────────────┤ │
│  │  🎉 Raya 2024       │    45    │ ✓ Live   │ Mar 1 - Apr 30   │ │
│  │  💒 Wedding Edition │    28    │ ✓ Live   │ Always           │ │
│  │  🆕 New Arrivals    │    12    │ ✓ Auto   │ Last 30 days     │ │
│  │  🔥 Flash Sale      │     8    │ ⏰ Sched │ Dec 12, 8PM-10PM │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  FLASH SALE CONFIGURATION:                                         │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  Name: 12.12 Flash Sale                                      │ │
│  │  Start: 2024-12-12 20:00    End: 2024-12-12 22:00           │ │
│  │  Discount: 40% off selected items                            │ │
│  │  Stock Limit: Max 50 units per SKU                           │ │
│  │  Purchase Limit: 2 per customer                              │ │
│  │  Countdown: ✓ Show on storefront                            │ │
│  │  Queue System: ✓ Enable virtual queue                       │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                    │
│  LOOKBOOKS:                                                        │
│  📸 Raya 2024 Lookbook - 15 styled outfits                        │
│  📸 Corporate Batik - 8 office-appropriate looks                   │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

#### Campaign Features

| Feature | Description |
|---------|-------------|
| **Collection Builder** | Drag-drop products into collections |
| **Auto-Collections** | Rules-based (New in 30 days, Price < X) |
| **Scheduled Publishing** | Publish/unpublish at specific times |
| **Flash Sale Engine** | Time-limited, stock-limited, purchase limits |
| **Lookbook Creator** | Combine products into styled presentations |
| **Banner Management** | Hero images, promotional banners |
| **Countdown Timers** | Configurable countdown display |

---

## 3. MICROSERVICE BOUNDARIES (Architecture)

### 3.1 Service Responsibility Map

Based on the existing architecture, here are the recommended service boundaries:

| Feature Domain | Service | Responsibilities |
|----------------|---------|-----------------|
| **Product Information** | `service-catalog` | Products, Variants, Categories, Collections, Attributes, Media, SEO |
| **Stock Management** | `service-inventory` | Stock levels, Warehouses, Transfers, Reservations, Movements |
| **Shopping** | `service-order` | Cart, Checkout, Orders, Payments, Fulfillment, Returns |
| **Customer Data** | `service-customer` | Profiles, Addresses, Wishlist, Fit Preferences, Segments, Loyalty |
| **Identity** | `service-auth` | Authentication, Users, Roles, Permissions, Sessions |
| **Resellers** | `service-agent` | Agent profiles, Commissions, Agent-specific pricing |
| **Analytics** | `service-reporting` | Sales reports, Inventory reports, Customer analytics |
| **Communication** | `service-notification` | Email, SMS, Push, Back-in-stock alerts |
| **Content** | `service-cms` (NEW) | Banners, Lookbooks, Landing pages, Flash sale configs |
| **Pricing** | `service-pricing` (NEW) | Discounts, Promotions, Flash sales, Dynamic pricing |
| **Search** | `service-search` (NEW) | Elasticsearch/Meilisearch for faceted search |

---

### 3.2 Feature → Service Map

| Feature | Responsible Service | Notes |
|---------|---------------------|-------|
| Product CRUD | `service-catalog` | Parent products + variants |
| Variant management | `service-catalog` | Size/Color options |
| Category tree | `service-catalog` | Hierarchical categories |
| Product images | `service-catalog` + MinIO | Store refs in catalog, files in MinIO |
| Stock levels | `service-inventory` | Per-variant (SKU) stock |
| Stock reservations | `service-inventory` | Called by Order Service |
| Multi-warehouse | `service-inventory` | Warehouse allocation logic |
| Low stock alerts | `service-inventory` → `service-notification` | Event-driven |
| Shopping cart | `service-order` | Ephemeral carts in Redis |
| Checkout | `service-order` | Calls Inventory for reservation |
| Order management | `service-order` | Status workflow |
| Payment processing | `service-order` | Curlec integration |
| Fulfillment | `service-order` | Picks from Inventory |
| Returns/Refunds | `service-order` | Return workflow |
| Customer profiles | `service-customer` | Demographics, preferences |
| Wishlist | `service-customer` | With variant specificity |
| Size/Fit profile | `service-customer` | Body measurements |
| Customer segments | `service-customer` | VIP, New, At-risk |
| Back-in-stock notify | `service-customer` → `service-notification` | Event-driven |
| Discounts/Coupons | `service-catalog` (existing) | Discount rules |
| Flash sales | `service-catalog` or new `service-pricing` | Time-limited offers |
| Collections | `service-catalog` | Product groupings |
| Search & Filter | `service-catalog` (or new Search) | Consider Elasticsearch |
| Agent commissions | `service-agent` | Commission calculation |
| Sales reports | `service-reporting` | Aggregates from Order |
| Email/SMS | `service-notification` | Transactional + marketing |

---

### 3.3 Inter-Service Communication

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          SERVICE COMMUNICATION                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  SYNCHRONOUS (REST/gRPC):                                              │
│  ┌─────────────┐      GET /stock/{sku}      ┌─────────────────┐        │
│  │   Order     │ ─────────────────────────► │   Inventory     │        │
│  │   Service   │ ◄───────────────────────── │   Service       │        │
│  └─────────────┘      {available: 12}       └─────────────────┘        │
│                                                                         │
│  ┌─────────────┐     POST /reserve          ┌─────────────────┐        │
│  │   Order     │ ─────────────────────────► │   Inventory     │        │
│  │   Service   │      {sku, qty, orderId}   │   Service       │        │
│  └─────────────┘                            └─────────────────┘        │
│                                                                         │
│  ASYNCHRONOUS (NATS):                                                  │
│  ┌─────────────┐    order.created           ┌─────────────────┐        │
│  │   Order     │ ════════════════════════►  │  Notification   │        │
│  │   Service   │                            │  Service        │        │
│  └─────────────┘                            └─────────────────┘        │
│                                                                         │
│  ┌─────────────┐    inventory.low_stock     ┌─────────────────┐        │
│  │  Inventory  │ ════════════════════════►  │  Notification   │        │
│  │   Service   │                            │  Service        │        │
│  └─────────────┘                            └─────────────────┘        │
│                                                                         │
│  ┌─────────────┐    inventory.restocked     ┌─────────────────┐        │
│  │  Inventory  │ ════════════════════════►  │  Customer       │        │
│  │   Service   │                            │  Service        │        │
│  └─────────────┘                            │  (back-in-stock)│        │
│                                             └─────────────────┘        │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 4. DATA MODEL

### 4.1 Product → Variant → Inventory Relationship

#### Products Table (service-catalog)

```sql
-- Parent Product
CREATE TABLE products (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) UNIQUE NOT NULL,
    description     TEXT,
    product_type    VARCHAR(50) NOT NULL, -- 'kain', 'baju_siap', 'aksesori', 'set_lengkap'
    base_price      DECIMAL(10,2) NOT NULL,
    compare_price   DECIMAL(10,2),         -- Strikethrough price
    category_id     UUID REFERENCES categories(id),
    status          VARCHAR(20) DEFAULT 'draft', -- 'draft', 'active', 'archived'
    is_featured     BOOLEAN DEFAULT FALSE,

    -- Batik-specific fields
    unit_type       VARCHAR(20) DEFAULT 'piece', -- 'meter', 'piece'
    min_order_qty   INTEGER DEFAULT 1,
    fabric_width    DECIMAL(5,2),          -- in cm
    fabric_composition VARCHAR(255),        -- "100% Silk", "Cotton Blend"
    is_tailorable   BOOLEAN DEFAULT FALSE,

    -- SEO
    meta_title      VARCHAR(255),
    meta_description TEXT,

    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);
```

#### Product Variants Table (service-catalog)

```sql
-- Child SKU (Size/Color combination)
CREATE TABLE product_variants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    sku             VARCHAR(50) UNIQUE NOT NULL, -- 'BSS-001-R-M'

    -- Variant attributes
    color           VARCHAR(50),
    color_code      VARCHAR(7),             -- '#FF0000' for swatch
    size            VARCHAR(20),
    length          DECIMAL(5,2),           -- For fabric (meters)

    -- Pricing (can override parent)
    price           DECIMAL(10,2),          -- NULL = use parent base_price
    compare_price   DECIMAL(10,2),
    cost_price      DECIMAL(10,2),          -- For profit calculation

    -- Physical attributes
    weight          DECIMAL(8,2),           -- in kg
    barcode         VARCHAR(50),

    -- Media
    image_id        UUID,                   -- Color-specific image

    -- Status
    position        INTEGER DEFAULT 0,      -- Sort order
    status          VARCHAR(20) DEFAULT 'active', -- 'active', 'inactive'

    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_variants_product ON product_variants(product_id);
CREATE INDEX idx_variants_sku ON product_variants(sku);
```

#### Inventory Items Table (service-inventory)

```sql
-- Stock per SKU per Warehouse
CREATE TABLE inventory_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku             VARCHAR(50) NOT NULL,   -- Links to variant
    warehouse_id    UUID NOT NULL REFERENCES warehouses(id),

    -- Stock levels
    quantity        INTEGER NOT NULL DEFAULT 0,
    reserved        INTEGER NOT NULL DEFAULT 0, -- Held for pending orders
    incoming        INTEGER NOT NULL DEFAULT 0, -- Expected from transfers/PO

    -- Computed (or use generated column)
    -- available = quantity - reserved

    -- Alerts
    low_threshold   INTEGER DEFAULT 5,      -- Alert when available < threshold

    updated_at      TIMESTAMP DEFAULT NOW(),

    UNIQUE(sku, warehouse_id)
);

CREATE INDEX idx_inventory_sku ON inventory_items(sku);
CREATE INDEX idx_inventory_warehouse ON inventory_items(warehouse_id);
```

#### Stock Movements Table (service-inventory)

```sql
-- Audit trail for all stock changes
CREATE TABLE stock_movements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_id    UUID NOT NULL REFERENCES inventory_items(id),

    -- Movement details
    type            VARCHAR(30) NOT NULL,   -- 'sale', 'return', 'transfer_in',
                                            -- 'transfer_out', 'adjustment', 'receiving'
    quantity        INTEGER NOT NULL,       -- Positive for in, negative for out

    -- Reference
    reference_type  VARCHAR(30),            -- 'order', 'transfer', 'adjustment'
    reference_id    VARCHAR(50),            -- Order ID, Transfer ID, etc.

    -- Metadata
    notes           TEXT,
    created_by      UUID,                   -- User who made the change
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_movements_inventory ON stock_movements(inventory_id);
CREATE INDEX idx_movements_reference ON stock_movements(reference_type, reference_id);
```

---

### 4.2 Flexible Variant Options (Alternative Model)

For products with varying option types (some have Size+Color, others have Size+Length):

```sql
-- Option types for a product
CREATE TABLE product_options (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name            VARCHAR(50) NOT NULL,   -- 'Color', 'Size', 'Length'
    position        INTEGER DEFAULT 0
);

-- Available values for each option
CREATE TABLE product_option_values (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    option_id       UUID NOT NULL REFERENCES product_options(id) ON DELETE CASCADE,
    value           VARCHAR(100) NOT NULL,  -- 'Red', 'M', '2 meters'
    color_code      VARCHAR(7),             -- For color swatches
    position        INTEGER DEFAULT 0
);

-- Junction: which option values make up each variant
CREATE TABLE variant_option_values (
    variant_id      UUID NOT NULL REFERENCES product_variants(id) ON DELETE CASCADE,
    option_value_id UUID NOT NULL REFERENCES product_option_values(id) ON DELETE CASCADE,
    PRIMARY KEY (variant_id, option_value_id)
);
```

---

### 4.3 Collections & Flash Sales

```sql
-- Collections (Seasonal, Curated)
CREATE TABLE collections (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(255) UNIQUE NOT NULL,
    description     TEXT,
    image_url       VARCHAR(500),

    -- Type
    type            VARCHAR(20) DEFAULT 'manual', -- 'manual', 'auto'
    rules           JSONB,                  -- For auto collections

    -- Scheduling
    start_date      TIMESTAMP,
    end_date        TIMESTAMP,

    -- Display
    position        INTEGER DEFAULT 0,
    status          VARCHAR(20) DEFAULT 'draft', -- 'draft', 'active', 'archived'

    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- Products in collections
CREATE TABLE collection_products (
    collection_id   UUID NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    position        INTEGER DEFAULT 0,
    PRIMARY KEY (collection_id, product_id)
);

-- Flash Sales
CREATE TABLE flash_sales (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,

    -- Timing
    start_time      TIMESTAMP NOT NULL,
    end_time        TIMESTAMP NOT NULL,

    -- Discount
    discount_type   VARCHAR(20) NOT NULL,   -- 'percentage', 'fixed'
    discount_value  DECIMAL(10,2) NOT NULL, -- 40 for 40%, or fixed amount

    -- Limits
    max_per_customer INTEGER DEFAULT 2,     -- Purchase limit per customer

    -- Status
    status          VARCHAR(20) DEFAULT 'scheduled', -- 'scheduled', 'active', 'ended'

    created_at      TIMESTAMP DEFAULT NOW()
);

-- Products/Variants in flash sale
CREATE TABLE flash_sale_items (
    flash_sale_id   UUID NOT NULL REFERENCES flash_sales(id) ON DELETE CASCADE,
    variant_id      UUID NOT NULL REFERENCES product_variants(id),

    stock_limit     INTEGER NOT NULL,       -- Max units for this flash sale
    sold_count      INTEGER DEFAULT 0,      -- Track flash sale purchases

    PRIMARY KEY (flash_sale_id, variant_id)
);
```

---

### 4.4 Customer Fashion Profile

```sql
-- Customer fit/style preferences (service-customer)
CREATE TABLE customer_profiles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     UUID NOT NULL UNIQUE,   -- From auth service

    -- Body measurements (optional)
    height_cm       INTEGER,
    weight_kg       INTEGER,
    chest_cm        INTEGER,
    waist_cm        INTEGER,
    hip_cm          INTEGER,

    -- Preferences
    preferred_fit   VARCHAR(20),            -- 'slim', 'regular', 'loose'
    preferred_sizes JSONB,                  -- {"tops": "M", "bottoms": "32"}

    -- Style preferences
    preferred_colors JSONB,                 -- ["Blue", "Green", "Earth tones"]
    preferred_patterns JSONB,               -- ["Floral", "Geometric"]
    occasions       JSONB,                  -- ["Casual", "Formal", "Wedding"]

    created_at      TIMESTAMP DEFAULT NOW(),
    updated_at      TIMESTAMP DEFAULT NOW()
);

-- Back-in-stock notifications
CREATE TABLE stock_notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     UUID NOT NULL,
    variant_id      UUID NOT NULL,          -- Specific SKU they want

    status          VARCHAR(20) DEFAULT 'pending', -- 'pending', 'notified', 'cancelled'
    notified_at     TIMESTAMP,

    created_at      TIMESTAMP DEFAULT NOW(),

    UNIQUE(customer_id, variant_id)
);
```

---

## 5. IMPLEMENTATION RECOMMENDATIONS

### 5.1 Priority Features (Phase-Based)

#### Phase 1: Core Fashion Functionality

| Feature | Service | Priority |
|---------|---------|----------|
| Variant matrix in Catalog | `service-catalog` | Critical |
| Per-SKU inventory tracking | `service-inventory` | Critical |
| Size guide integration | `service-catalog` | High |
| Wishlist with variant support | `service-customer` | High |
| Stock availability API | `service-inventory` | Critical |

#### Phase 2: Discovery & Engagement

| Feature | Service | Priority |
|---------|---------|----------|
| Faceted search | `service-catalog` or new Search | High |
| Collections management | `service-catalog` | High |
| Back-in-stock notifications | `service-customer` + `service-notification` | Medium |
| Customer fit profiles | `service-customer` | Medium |

#### Phase 3: Campaign & Sales

| Feature | Service | Priority |
|---------|---------|----------|
| Flash sale engine | `service-catalog` or new Pricing | High |
| Lookbook creator | `service-catalog` | Medium |
| Dynamic pricing rules | `service-catalog` | Medium |
| Loyalty points system | `service-customer` | Low |

---

### 5.2 Technical Considerations

| Concern | Recommendation |
|---------|----------------|
| **Real-time stock** | Redis cache for hot SKUs, invalidate on stock change |
| **Flash sale concurrency** | Redis DECR for atomic stock deduction, prevent overselling |
| **Search performance** | Meilisearch for faceted search (lighter than Elasticsearch) |
| **Image handling** | CDN (Cloudflare) in front of MinIO for global delivery |
| **Cart persistence** | Redis with 7-day TTL, merge anonymous cart on login |
| **Variant matrix loading** | Single API call returns all variants with stock status |

---

### 5.3 API Design for Variant Stock

```go
// GET /api/v1/products/{id}/availability
// Returns stock matrix for storefront PDP

type AvailabilityResponse struct {
    ProductID string                      `json:"product_id"`
    Variants  []VariantAvailability       `json:"variants"`
    Matrix    map[string]map[string]Stock `json:"matrix"` // color -> size -> stock
}

type VariantAvailability struct {
    VariantID    string `json:"variant_id"`
    SKU          string `json:"sku"`
    Color        string `json:"color"`
    Size         string `json:"size"`
    Price        float64 `json:"price"`
    Available    int    `json:"available"`
    Status       string `json:"status"` // "in_stock", "low_stock", "out_of_stock"
}

type Stock struct {
    Available int    `json:"available"`
    Status    string `json:"status"`
}
```

---

## 6. APPENDIX

### 6.1 Existing Service Ports

| Service | Port | Status |
|---------|------|--------|
| service-auth | 8001 | Existing |
| service-catalog | 8002 | Existing |
| service-inventory | 8003 | Existing |
| service-customer | 8004 | Existing |
| service-order | 8005 | Existing |
| service-agent | 8006 | Existing |
| service-reporting | 8007 | Existing |
| service-notification | 8008 | Existing |

### 6.2 Related Documentation

- [API Contracts](./API_CONTRACTS.md)
- [Admin UI Plan](./ADMIN_UI_PLAN.md)
- [Production Readiness Checklist](./PRODUCTION-READINESS-CHECKLIST.md)

---

**Document Owner**: Product Architecture Team
**Review Cycle**: Quarterly
**Next Review**: March 2025
