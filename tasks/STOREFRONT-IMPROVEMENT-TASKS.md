# Frontend Storefront Improvement Tasks

> **Project:** Kilang Desa Murni Batik - Premium Fashion eCommerce
> **Stack:** Next.js 14, TypeScript, Tailwind, Zustand
> **Backend:** Go Microservices (REST API)
> **Goal:** Premium, Fast, Visually Rich Shopping Experience

---

## API Status Legend

| Symbol | Meaning |
|--------|---------|
| ✅ API EXISTS | Backend endpoint ready to use |
| 🔨 NEED API | New backend endpoint required |
| 🎨 FRONTEND ONLY | No API needed, pure frontend |

---

## Existing Backend APIs Available

### Cart API (service-order)
```
✅ GET    /api/v1/cart                    - Get cart
✅ POST   /api/v1/cart/items              - Add item
✅ PUT    /api/v1/cart/items/:itemId      - Update quantity
✅ DELETE /api/v1/cart/items/:itemId      - Remove item
✅ DELETE /api/v1/cart                    - Clear cart
✅ POST   /api/v1/cart/coupon             - Apply coupon
✅ DELETE /api/v1/cart/coupon             - Remove coupon
```

### Wishlist API (service-customer)
```
✅ GET    /api/v1/customer/wishlist                    - Get wishlist
✅ POST   /api/v1/customer/wishlist                    - Add to wishlist
✅ DELETE /api/v1/customer/wishlist/:productId        - Remove from wishlist
✅ DELETE /api/v1/customer/wishlist/items/:itemId     - Remove by item ID
✅ PATCH  /api/v1/customer/wishlist/items/:itemId     - Update (notify_on_sale)
✅ GET    /api/v1/customer/wishlist/check/:productId  - Check if in wishlist
✅ GET    /api/v1/customer/wishlist/count             - Get count
```

### Catalog API (service-catalog)
```
✅ GET    /api/v1/catalog/products                    - List products
✅ GET    /api/v1/catalog/products/:slug              - Get product
✅ GET    /api/v1/catalog/products/:slug/variants     - Get variants
✅ GET    /api/v1/catalog/products/:slug/availability - Variant matrix
✅ GET    /api/v1/catalog/products/:slug/related      - Related products
✅ GET    /api/v1/catalog/products/featured           - Featured
✅ GET    /api/v1/catalog/products/new                - New arrivals
✅ GET    /api/v1/catalog/products/bestsellers        - Best sellers
✅ GET    /api/v1/catalog/filters                     - Faceted filters
✅ GET    /api/v1/catalog/categories                  - Categories
✅ GET    /api/v1/search                              - Search products
✅ GET    /api/v1/search/suggestions                  - Search suggestions
```

### Inventory API (service-inventory)
```
✅ GET    /api/v1/inventory/availability/:productId   - Stock availability
```

---

## Phase 1: Quick Wins (Frontend Only)

### STORE-001: Optimistic Cart Updates
**Priority:** 🔴 Critical | **Type:** 🎨 FRONTEND ONLY
**Location:** `lib/stores/cart.ts`, `components/product/AddToCartButton.tsx`

**Problem:** Cart waits for API before updating UI (feels slow).

**Backend APIs:** ✅ All exist
- `POST /api/v1/cart/items` - Add item
- `PUT /api/v1/cart/items/:itemId` - Update
- `DELETE /api/v1/cart/items/:itemId` - Remove

**Tasks:**
- [ ] Add `pendingOperations` Map to cart store
- [ ] Update UI immediately on add/remove/update
- [ ] Sync with server in background
- [ ] Rollback on API failure + show toast error
- [ ] Add loading spinner during sync
- [ ] Show success checkmark animation

**Implementation:**
```typescript
// lib/stores/cart.ts - Add optimistic pattern
addItem: async (item) => {
  const tempId = `temp-${Date.now()}`;

  // 1. Optimistic update (instant)
  set(state => ({
    items: [...state.items, { ...item, id: tempId }],
    pendingOps: new Map(state.pendingOps).set(tempId, 'add')
  }));

  try {
    // 2. Server sync
    const res = await catalogClient.post('/cart/items', item);

    // 3. Replace temp ID with real ID
    set(state => ({
      items: state.items.map(i =>
        i.id === tempId ? { ...i, id: res.data.id } : i
      ),
      pendingOps: new Map([...state.pendingOps].filter(([k]) => k !== tempId))
    }));
  } catch (error) {
    // 4. Rollback
    set(state => ({
      items: state.items.filter(i => i.id !== tempId),
      pendingOps: new Map([...state.pendingOps].filter(([k]) => k !== tempId))
    }));
    toast.error('Failed to add item');
  }
}
```

---

### STORE-002: Optimistic Wishlist Toggle
**Priority:** 🔴 Critical | **Type:** 🎨 FRONTEND ONLY
**Location:** `lib/stores/wishlist.ts`, `components/product/WishlistButton.tsx`

**Backend APIs:** ✅ All exist
- `POST /api/v1/customer/wishlist` - Add
- `DELETE /api/v1/customer/wishlist/:productId` - Remove
- `GET /api/v1/customer/wishlist/check/:productId` - Check status

**Tasks:**
- [ ] Add `pendingToggles` Set to wishlist store
- [ ] Toggle heart icon immediately on click
- [ ] Sync with server in background
- [ ] Rollback + error toast on failure
- [ ] Add scale animation on toggle

---

### STORE-003: Low Stock Indicators
**Priority:** 🟡 High | **Type:** 🎨 FRONTEND ONLY (data from existing availability API)
**Location:** `components/product/ProductCard.tsx`, `components/product/StockIndicator.tsx`

**Backend APIs:** ✅ Already returns stock data
- `GET /api/v1/catalog/products/:slug/availability` returns `status: 'in_stock' | 'low_stock' | 'out_of_stock'`

**Tasks:**
- [ ] Add "Only X left" badge when `available <= 5`
- [ ] Add pulsing dot for `status === 'low_stock'`
- [ ] Show "Last one!" when `available === 1`
- [ ] Strikethrough + grey for out-of-stock sizes
- [ ] Add urgency color (amber/red)

---

### STORE-004: Gallery Zoom & Lightbox
**Priority:** 🟡 High | **Type:** 🎨 FRONTEND ONLY
**Location:** `components/product/ProductGallery.tsx`

**Tasks:**
- [ ] Add hover zoom (magnifier lens effect)
- [ ] Add pinch-to-zoom on mobile
- [ ] Add fullscreen lightbox mode
- [ ] Add thumbnail navigation for mobile
- [ ] Add image loading skeleton
- [ ] Switch images when color changes (use variant images)

---

### STORE-005: Price Display Enhancement
**Priority:** 🟡 High | **Type:** 🎨 FRONTEND ONLY
**Location:** `components/product/PriceCalculator.tsx`

**Tasks:**
- [ ] Show strikethrough original price prominently
- [ ] Add discount percentage badge (-20%)
- [ ] Add "You save RM X" message
- [ ] Animate price change on variant selection
- [ ] Add installment hint ("or 3x RM XX")

---

### STORE-006: Mobile Filter Sheet
**Priority:** 🟡 High | **Type:** 🎨 FRONTEND ONLY
**Location:** `components/product/FilterSidebar.tsx`

**Tasks:**
- [ ] Convert to bottom sheet on mobile (use Sheet from Radix)
- [ ] Add sticky "Show X Results" button
- [ ] Show active filter count badge
- [ ] Improve touch targets (48px min)
- [ ] Add smooth slide animation

---

## Phase 2: Needs New Backend APIs

### STORE-007: Product Reviews & Ratings
**Priority:** 🔴 Critical | **Type:** 🔨 NEED API
**Impact:** Trust & Conversions (+15-30%)

**New Backend APIs Required:**
```go
// service-catalog/internal/handlers/review_handler.go

GET    /api/v1/catalog/products/:slug/reviews
       Query: page, limit, rating, sort (newest, helpful, highest, lowest)
       Response: { reviews: Review[], total, average_rating, rating_distribution }

POST   /api/v1/catalog/products/:slug/reviews
       Body: { rating: 1-5, title, content, images?: string[] }
       Auth: Required

POST   /api/v1/reviews/:reviewId/helpful
       Body: { helpful: boolean }
       Auth: Required

GET    /api/v1/catalog/products/:slug/reviews/summary
       Response: { average_rating, total_reviews, rating_distribution, fit_feedback }
```

**Database Schema:**
```sql
CREATE TABLE product_reviews (
  id UUID PRIMARY KEY,
  product_id UUID REFERENCES products(id),
  user_id UUID REFERENCES users(id),
  order_id UUID REFERENCES orders(id),  -- Verified purchase
  rating INT CHECK (rating >= 1 AND rating <= 5),
  title VARCHAR(200),
  content TEXT,
  images JSONB,  -- Array of image URLs
  helpful_count INT DEFAULT 0,
  is_verified_purchase BOOLEAN DEFAULT false,
  fit_feedback VARCHAR(20),  -- 'runs_small', 'true_to_size', 'runs_large'
  status VARCHAR(20) DEFAULT 'pending',  -- pending, approved, rejected
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);

CREATE TABLE review_helpful_votes (
  id UUID PRIMARY KEY,
  review_id UUID REFERENCES product_reviews(id),
  user_id UUID REFERENCES users(id),
  is_helpful BOOLEAN,
  created_at TIMESTAMP,
  UNIQUE(review_id, user_id)
);
```

**Frontend Components:**
```
components/reviews/
├── ReviewSummary.tsx      - Average rating, distribution bars
├── ReviewList.tsx         - Paginated review list
├── ReviewCard.tsx         - Single review with photos
├── WriteReviewModal.tsx   - Review form with star rating
├── RatingStars.tsx        - Star display component
├── ReviewFilters.tsx      - Filter by rating
└── FitFeedback.tsx        - "Runs small/large" display
```

**Tasks:**
- [ ] Create review database schema
- [ ] Create review_handler.go with CRUD
- [ ] Create ReviewSummary component
- [ ] Create ReviewList with pagination
- [ ] Create ReviewCard with images
- [ ] Create WriteReviewModal
- [ ] Add review count to ProductCard
- [ ] Add fit feedback aggregation

---

### STORE-008: Recently Viewed Products ✅ COMPLETED
**Priority:** 🟢 Medium | **Type:** 🎨 FRONTEND ONLY (localStorage)
**Completed:** December 2024

**Implementation (Option A: Frontend Only):**
```typescript
// lib/stores/recently-viewed.ts - Zustand + localStorage persist
interface RecentlyViewedStore {
  items: RecentlyViewedProduct[];  // Max 20
  addProduct: (product) => void;
  removeProduct: (productId) => void;
  clearAll: () => void;
  getRecentProducts: (limit?, excludeId?) => RecentlyViewedProduct[];
  hasViewed: (productId) => boolean;
}
```

**Files Created:**
- `lib/stores/recently-viewed.ts` - Zustand store with localStorage
- `components/product/RecentlyViewed.tsx` - Carousel + Compact variant
- `components/product/RecentlyViewedTracker.tsx` - PDP view tracker

**Tasks:**
- [x] Create recently-viewed store (Zustand + localStorage)
- [x] Track product views on PDP load
- [x] Create RecentlyViewed carousel component
- [x] Add to PDP (below product info)
- [x] Add to homepage (before footer)

---

### STORE-009: AI Recommendations ✅ COMPLETED
**Priority:** 🟢 Medium | **Type:** ✅ API + Frontend Done
**Impact:** +20-30% AOV
**Completed:** December 2024

**Backend APIs Created:**
```
✅ GET /api/v1/recommendations/also-bought/:productId
✅ GET /api/v1/recommendations/complete-look/:productId
✅ GET /api/v1/recommendations/personalized
✅ GET /api/v1/recommendations/trending
```

**Files Created:**
- `service-catalog/internal/handlers/recommendation_handler.go`
- `service-catalog/internal/models/recommendation.go`
- `frontend-storefront/components/product/ProductRecommendations.tsx`
- `frontend-storefront/lib/api/catalog.ts` (API functions added)

**Tasks:**
- [x] Create recommendations service
- [x] Implement "Also Bought" (fallback to same category)
- [x] Implement "Complete Look" (color matching)
- [x] Implement "Trending" (by sales/views)
- [x] Create recommendation carousel component
- [x] Add to PDP page

---

### STORE-010: Product Bundles ✅ COMPLETED
**Priority:** 🟢 Medium | **Type:** ✅ API + Frontend Done
**Impact:** +15% AOV
**Completed:** December 2024

**Backend APIs Created:**
```
✅ GET  /api/v1/catalog/products/:slug/bundles - Get bundles for product
✅ GET  /api/v1/admin/bundles - List all bundles (admin)
✅ POST /api/v1/admin/bundles - Create bundle (admin)
✅ PUT  /api/v1/admin/bundles/:id - Update bundle (admin)
✅ DELETE /api/v1/admin/bundles/:id - Delete bundle (admin)
```

**Database Models (auto-migrated):**
- `catalog.product_bundles` - Bundle info with discount settings
- `catalog.bundle_items` - Products in each bundle

**Files Created:**
- `service-catalog/internal/models/recommendation.go` (ProductBundle, BundleItem models)
- `service-catalog/internal/handlers/recommendation_handler.go` (bundle endpoints)
- `frontend-storefront/components/product/FrequentlyBoughtTogether.tsx`
- `frontend-storefront/lib/api/catalog.ts` (bundle API functions)

**Tasks:**
- [x] Create bundle database schema (GORM auto-migrate)
- [x] Create bundle endpoints (public + admin)
- [x] Create "Frequently Bought Together" component
- [x] Show savings amount prominently
- [x] "Add Bundle to Cart" with selection

---

### STORE-011: Size & Fit Intelligence ✅ MOSTLY COMPLETE
**Priority:** 🟡 High | **Type:** 🎨 FRONTEND ONLY (core features done)
**Status:** Core features implemented, optional enhancements available

**Existing Implementation:**
- `components/product/SizeGuideDialog.tsx` - Full-featured size guide with:
  - Size chart table with measurements
  - Size finder calculator (bust, waist, hip, height inputs)
  - Recommendation algorithm (calculates best match)
  - Bilingual measurement guide (Malay/English)
  - Print functionality
  - Default charts for Baju Kurung & Baju Melayu
- `service-catalog` - Size chart CRUD API exists

**Existing APIs:** ✅
- `GET /api/v1/size-charts` - List size charts
- `GET /api/v1/size-charts/:id` - Get specific chart
- `POST/PUT/DELETE /api/v1/size-charts` - Admin CRUD

**Integration:**
- Integrated in `ProductActions.tsx` via "Find My Size" button
- Opens dialog with size recommendation

**Tasks:**
- [x] Create size recommendation algorithm (in SizeGuideDialog)
- [x] Create "Find My Size" modal (SizeGuideDialog)
- [x] Show recommendation on size selection
- [ ] (Optional) Store customer measurements in profile
- [ ] (Optional) Aggregate fit feedback from reviews

---

## Phase 3: Polish & Performance

### STORE-012: Loading Skeletons
**Priority:** 🟡 High | **Type:** 🎨 FRONTEND ONLY
**Location:** Multiple components

**Tasks:**
- [ ] ProductCard skeleton (exists: improve)
- [ ] ProductGallery skeleton
- [ ] FilterSidebar skeleton
- [ ] ReviewList skeleton
- [ ] Cart page skeleton
- [ ] Consistent shimmer animation

---

### STORE-013: Error & Empty States
**Priority:** 🟡 High | **Type:** 🎨 FRONTEND ONLY

**Tasks:**
- [ ] Create reusable EmptyState component
- [ ] Search: "No products found" with suggestions
- [ ] Wishlist: "Your wishlist is empty"
- [ ] Cart: "Your cart is empty"
- [ ] Orders: "No orders yet"
- [ ] Add retry button on API errors
- [ ] Add offline detection banner

---

### STORE-014: SEO Structured Data
**Priority:** 🟢 Medium | **Type:** 🎨 FRONTEND ONLY

**Tasks:**
- [ ] Add JSON-LD Product schema
- [ ] Add BreadcrumbList schema
- [ ] Add Review schema (when reviews exist)
- [ ] Add Organization schema
- [ ] Verify with Google Rich Results Test

---

## Implementation Priority

### Sprint 1 (Week 1): Instant Feel
| Task | Type | Effort |
|------|------|--------|
| STORE-001 Optimistic Cart | 🎨 Frontend | 1 day |
| STORE-002 Optimistic Wishlist | 🎨 Frontend | 0.5 day |
| STORE-003 Low Stock | 🎨 Frontend | 0.5 day |
| STORE-012 Skeletons | 🎨 Frontend | 1 day |

### Sprint 2 (Week 2): Visual Premium
| Task | Type | Effort |
|------|------|--------|
| STORE-004 Gallery Zoom | 🎨 Frontend | 2 days |
| STORE-005 Price Display | 🎨 Frontend | 0.5 day |
| STORE-006 Mobile Filters | 🎨 Frontend | 1 day |
| STORE-013 Empty States | 🎨 Frontend | 1 day |

### Sprint 3 (Week 3-4): Reviews System
| Task | Type | Effort |
|------|------|--------|
| STORE-007 Reviews Backend | 🔨 Backend | 3 days |
| STORE-007 Reviews Frontend | 🎨 Frontend | 3 days |

### Sprint 4 (Week 5): Intelligence ✅ COMPLETE
| Task | Type | Effort | Status |
|------|------|--------|--------|
| STORE-008 Recently Viewed | 🎨 Frontend | 1 day | ✅ Done |
| STORE-011 Size Fit | 🎨 Frontend | Already done | ✅ Already Implemented |

### Sprint 5 (Week 6): Revenue Features ✅ COMPLETE
| Task | Type | Effort | Status |
|------|------|--------|--------|
| STORE-009 Recommendations | 🔨 Backend + Frontend | 3 days | ✅ Done |
| STORE-010 Bundles | 🔨 Backend + Frontend | 2 days | ✅ Done |

### Sprint 6 (Week 7): Polish
| Task | Type | Effort |
|------|------|--------|
| STORE-014 SEO | 🎨 Frontend | 1 day |
| Testing & Bug Fixes | Both | 2 days |

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Add to Cart Response | ~500ms perceived | <100ms perceived |
| Wishlist Toggle | ~300ms perceived | <50ms perceived |
| Review Coverage | 0% | 50% products |
| Mobile Filter Usage | Unknown | Track & improve |
| Conversion Rate | Baseline | +15% |
| Average Order Value | Baseline | +20% |

---

## Files to Create/Modify Summary

### New Files (Frontend)
```
components/reviews/
├── ReviewSummary.tsx
├── ReviewList.tsx
├── ReviewCard.tsx
├── WriteReviewModal.tsx
├── RatingStars.tsx
└── index.ts

components/product/RecentlyViewed.tsx
components/common/EmptyState.tsx

lib/stores/recently-viewed.ts
lib/api/reviews.ts
```

### New Files (Backend)
```
service-catalog/internal/handlers/review_handler.go
service-catalog/internal/repository/review_repository.go
service-catalog/internal/models/review.go

service-catalog/internal/handlers/recommendation_handler.go
service-catalog/internal/services/recommendation_service.go

service-catalog/internal/handlers/bundle_handler.go
```

### Modify Files
```
lib/stores/cart.ts              - Add optimistic updates
lib/stores/wishlist.ts          - Add optimistic updates
components/product/AddToCartButton.tsx
components/product/WishlistButton.tsx
components/product/ProductCard.tsx
components/product/ProductGallery.tsx
components/product/FilterSidebar.tsx
components/product/StockIndicator.tsx
components/product/PriceCalculator.tsx
app/(shop)/products/[slug]/page.tsx
```

---

*Document Version: 2.0*
*Updated: December 2024*
*Project: Kilang Desa Murni Batik Storefront*
