# Technical Frontend Specification: Fashion eCommerce Storefront

> **Version**: 1.0.0
> **Stack**: Next.js 14 (App Router), TypeScript, Tailwind CSS
> **Backend**: Go Microservices via REST API
> **Design Philosophy**: Premium, Fast, Visually Rich

---

## Executive Summary

This specification defines the architecture for three core shopping experience modules:

1. **Smart Product Detail Page (PDP)** - Complex variant state management
2. **Optimistic UI Actions** - Instant feedback for cart/wishlist operations
3. **Visual Filtering System (PLP)** - Fashion-first filter components with URL sync

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         STOREFRONT ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────────┐    ┌──────────────────────┐               │
│  │   Server Components  │    │   Client Components  │               │
│  │   (SEO + Speed)      │    │   (Interactivity)    │               │
│  ├──────────────────────┤    ├──────────────────────┤               │
│  │ • Product Info       │    │ • Variant Selector   │               │
│  │ • SEO Metadata       │    │ • Image Gallery      │               │
│  │ • Initial Gallery    │    │ • Add to Cart        │               │
│  │ • Reviews Summary    │    │ • Wishlist Toggle    │               │
│  │ • Related Products   │    │ • Quantity Picker    │               │
│  │ • Breadcrumbs        │    │ • Size Guide Modal   │               │
│  └──────────────────────┘    │ • Filter Panel       │               │
│                              │ • Cart Drawer        │               │
│                              └──────────────────────┘               │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                     SHARED STATE LAYER                        │   │
│  ├──────────────────────────────────────────────────────────────┤   │
│  │  Zustand Store: Cart, Wishlist, Recently Viewed, User Prefs  │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Module 1: Smart Product Detail Page (PDP)

### 1.1 The Variant Matrix Problem

**Challenge**: A product has 5 colors × 6 sizes = 30 potential variants. When user selects "Red", we must:
- Disable unavailable sizes (e.g., XL out of stock)
- Switch image gallery to Red-only images
- Update price if variant-specific pricing exists

### 1.2 Data Strategy Decision

| Approach | Payload | Speed | SEO | Recommendation |
|----------|---------|-------|-----|----------------|
| **All Variants Upfront** | ~15KB | Instant interactions | ✅ Full SSR | **✅ RECOMMENDED** |
| Fetch on Demand | Small initial | 200ms delay per click | ⚠️ Partial | Not ideal for UX |

**Rationale**: Fashion products rarely exceed 50 variants. A 15KB payload is negligible vs. the UX benefit of instant variant switching. This also enables full Server-Side Rendering for SEO.

### 1.3 Variant Data Structure

```typescript
// types/product.ts

export interface ProductVariant {
  id: string;
  sku: string;
  colorId: string;
  sizeId: string;
  price: number;
  compareAtPrice?: number;
  inventory: number;
  available: boolean;
  images: ProductImage[];  // Variant-specific images
}

export interface ProductColor {
  id: string;
  name: string;
  hex: string;              // For visual swatch: "#C41E3A"
  slug: string;             // URL-friendly: "ruby-red"
  swatch?: string;          // Optional: pattern image URL
}

export interface ProductSize {
  id: string;
  name: string;             // "XL", "42", "Large"
  displayOrder: number;
  measurements?: {
    chest?: string;
    waist?: string;
    length?: string;
  };
}

export interface Product {
  id: string;
  slug: string;
  name: string;
  description: string;
  basePrice: number;
  compareAtPrice?: number;

  // Variant Configuration
  colors: ProductColor[];
  sizes: ProductSize[];
  variants: ProductVariant[];

  // Media
  images: ProductImage[];   // Default/hero images

  // SEO
  metaTitle: string;
  metaDescription: string;

  // Relations
  categoryId: string;
  collectionIds: string[];
  tags: string[];
}

// Pre-computed lookup for O(1) variant access
export type VariantMatrix = Map<string, ProductVariant | null>;
// Key format: "colorId:sizeId" → variant or null if doesn't exist
```

### 1.4 Variant Matrix Builder

```typescript
// lib/product/variant-matrix.ts

export function buildVariantMatrix(variants: ProductVariant[]): VariantMatrix {
  const matrix = new Map<string, ProductVariant | null>();

  variants.forEach(variant => {
    const key = `${variant.colorId}:${variant.sizeId}`;
    matrix.set(key, variant);
  });

  return matrix;
}

export function getVariant(
  matrix: VariantMatrix,
  colorId: string,
  sizeId: string
): ProductVariant | null {
  return matrix.get(`${colorId}:${sizeId}`) ?? null;
}

export function getAvailableSizes(
  matrix: VariantMatrix,
  colorId: string,
  allSizes: ProductSize[]
): Array<ProductSize & { available: boolean; inventory: number }> {
  return allSizes.map(size => {
    const variant = getVariant(matrix, colorId, size.id);
    return {
      ...size,
      available: variant?.available ?? false,
      inventory: variant?.inventory ?? 0,
    };
  });
}

export function getAvailableColors(
  matrix: VariantMatrix,
  sizeId: string | null,
  allColors: ProductColor[]
): Array<ProductColor & { available: boolean; hasStock: boolean }> {
  return allColors.map(color => {
    // If no size selected, check if ANY size is available for this color
    if (!sizeId) {
      const hasAnyStock = Array.from(matrix.entries()).some(([key, variant]) =>
        key.startsWith(`${color.id}:`) && variant?.available
      );
      return { ...color, available: true, hasStock: hasAnyStock };
    }

    const variant = getVariant(matrix, color.id, sizeId);
    return {
      ...color,
      available: variant?.available ?? false,
      hasStock: (variant?.inventory ?? 0) > 0,
    };
  });
}
```

### 1.5 Component Architecture (Server vs Client Split)

```
┌─────────────────────────────────────────────────────────────────┐
│                    PDP Component Tree                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  app/products/[slug]/page.tsx (SERVER - SSR + SEO)              │
│  ├── generateMetadata()           ← SEO meta tags               │
│  ├── <Breadcrumbs />              ← Server Component            │
│  ├── <ProductGallery />           ← Server renders initial,     │
│  │                                   Client handles interaction │
│  ├── <ProductInfo />              ← Server Component (name,     │
│  │                                   description, base price)   │
│  ├── <VariantSelector />          ← CLIENT COMPONENT (★)        │
│  │   ├── <ColorSwatches />                                      │
│  │   ├── <SizeSelector />                                       │
│  │   └── <PriceDisplay />                                       │
│  ├── <AddToCartButton />          ← CLIENT COMPONENT (★)        │
│  ├── <WishlistButton />           ← CLIENT COMPONENT (★)        │
│  ├── <ProductTabs />              ← Server Component            │
│  │   ├── Description Tab                                        │
│  │   ├── Size Guide Tab                                         │
│  │   └── Reviews Tab                                            │
│  └── <RelatedProducts />          ← Server Component            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.6 Implementation: Variant Selector (Client Component)

```typescript
// components/product/VariantSelector.tsx
'use client';

import { useState, useMemo, useCallback } from 'react';
import { cn } from '@/lib/utils';
import {
  Product,
  ProductVariant,
  buildVariantMatrix,
  getAvailableSizes,
  getAvailableColors,
  getVariant
} from '@/lib/product';

interface VariantSelectorProps {
  product: Product;
  initialColorId?: string;
  initialSizeId?: string;
  onVariantChange: (variant: ProductVariant | null) => void;
}

export function VariantSelector({
  product,
  initialColorId,
  initialSizeId,
  onVariantChange,
}: VariantSelectorProps) {
  // Pre-compute variant matrix once
  const variantMatrix = useMemo(
    () => buildVariantMatrix(product.variants),
    [product.variants]
  );

  // State
  const [selectedColorId, setSelectedColorId] = useState<string>(
    initialColorId ?? product.colors[0]?.id ?? ''
  );
  const [selectedSizeId, setSelectedSizeId] = useState<string | null>(
    initialSizeId ?? null
  );

  // Derived: Available options based on current selection
  const availableSizes = useMemo(
    () => getAvailableSizes(variantMatrix, selectedColorId, product.sizes),
    [variantMatrix, selectedColorId, product.sizes]
  );

  const availableColors = useMemo(
    () => getAvailableColors(variantMatrix, selectedSizeId, product.colors),
    [variantMatrix, selectedSizeId, product.colors]
  );

  // Derived: Current variant
  const selectedVariant = useMemo(() => {
    if (!selectedColorId || !selectedSizeId) return null;
    return getVariant(variantMatrix, selectedColorId, selectedSizeId);
  }, [variantMatrix, selectedColorId, selectedSizeId]);

  // Handlers
  const handleColorChange = useCallback((colorId: string) => {
    setSelectedColorId(colorId);

    // If current size is unavailable in new color, reset size
    const newVariant = selectedSizeId
      ? getVariant(variantMatrix, colorId, selectedSizeId)
      : null;

    if (selectedSizeId && !newVariant?.available) {
      setSelectedSizeId(null);
      onVariantChange(null);
    } else {
      onVariantChange(newVariant);
    }
  }, [variantMatrix, selectedSizeId, onVariantChange]);

  const handleSizeChange = useCallback((sizeId: string) => {
    setSelectedSizeId(sizeId);
    const variant = getVariant(variantMatrix, selectedColorId, sizeId);
    onVariantChange(variant);
  }, [variantMatrix, selectedColorId, onVariantChange]);

  const selectedColor = product.colors.find(c => c.id === selectedColorId);

  return (
    <div className="space-y-6">
      {/* Color Selector */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <span className="text-sm font-medium text-gray-900">
            Color: <span className="font-normal">{selectedColor?.name}</span>
          </span>
        </div>
        <div className="flex flex-wrap gap-2">
          {availableColors.map((color) => (
            <button
              key={color.id}
              onClick={() => handleColorChange(color.id)}
              disabled={!color.hasStock}
              className={cn(
                'relative w-10 h-10 rounded-full border-2 transition-all',
                'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black',
                selectedColorId === color.id
                  ? 'border-black ring-1 ring-black'
                  : 'border-gray-200 hover:border-gray-400',
                !color.hasStock && 'opacity-40 cursor-not-allowed'
              )}
              title={color.name}
              aria-label={`Select ${color.name} color${!color.hasStock ? ' (out of stock)' : ''}`}
            >
              {/* Color Swatch */}
              {color.swatch ? (
                <img
                  src={color.swatch}
                  alt={color.name}
                  className="w-full h-full rounded-full object-cover"
                />
              ) : (
                <span
                  className="absolute inset-1 rounded-full"
                  style={{ backgroundColor: color.hex }}
                />
              )}

              {/* Out of Stock Diagonal Line */}
              {!color.hasStock && (
                <span className="absolute inset-0 flex items-center justify-center">
                  <span className="w-full h-0.5 bg-gray-400 rotate-45 transform" />
                </span>
              )}
            </button>
          ))}
        </div>
      </div>

      {/* Size Selector */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <span className="text-sm font-medium text-gray-900">Size</span>
          <button className="text-sm text-gray-600 underline hover:text-black">
            Size Guide
          </button>
        </div>
        <div className="flex flex-wrap gap-2">
          {availableSizes.map((size) => (
            <button
              key={size.id}
              onClick={() => handleSizeChange(size.id)}
              disabled={!size.available}
              className={cn(
                'min-w-[3rem] h-12 px-4 rounded-lg border text-sm font-medium transition-all',
                'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black',
                selectedSizeId === size.id
                  ? 'border-black bg-black text-white'
                  : size.available
                    ? 'border-gray-200 bg-white text-gray-900 hover:border-black'
                    : 'border-gray-100 bg-gray-50 text-gray-300 cursor-not-allowed line-through'
              )}
              aria-label={`Select size ${size.name}${!size.available ? ' (out of stock)' : ''}`}
            >
              {size.name}
            </button>
          ))}
        </div>

        {/* Low Stock Warning */}
        {selectedVariant && selectedVariant.inventory > 0 && selectedVariant.inventory <= 5 && (
          <p className="mt-2 text-sm text-amber-600 flex items-center gap-1">
            <span className="w-2 h-2 bg-amber-500 rounded-full animate-pulse" />
            Only {selectedVariant.inventory} left in stock
          </p>
        )}
      </div>

      {/* Price Display */}
      <div className="pt-2">
        <PriceDisplay
          price={selectedVariant?.price ?? product.basePrice}
          compareAtPrice={selectedVariant?.compareAtPrice ?? product.compareAtPrice}
        />
      </div>
    </div>
  );
}

function PriceDisplay({
  price,
  compareAtPrice
}: {
  price: number;
  compareAtPrice?: number;
}) {
  const hasDiscount = compareAtPrice && compareAtPrice > price;
  const discountPercent = hasDiscount
    ? Math.round((1 - price / compareAtPrice) * 100)
    : 0;

  return (
    <div className="flex items-baseline gap-3">
      <span className="text-2xl font-semibold text-gray-900">
        RM {price.toFixed(2)}
      </span>
      {hasDiscount && (
        <>
          <span className="text-lg text-gray-400 line-through">
            RM {compareAtPrice.toFixed(2)}
          </span>
          <span className="px-2 py-0.5 text-sm font-medium text-red-700 bg-red-50 rounded">
            -{discountPercent}%
          </span>
        </>
      )}
    </div>
  );
}
```

---

## Module 2: High-Performance Optimistic Actions

### 2.1 The "Instant Feel" Requirement

Users expect immediate feedback. A 200ms API delay feels sluggish. Solution: **Optimistic Updates**.

```
┌──────────────────────────────────────────────────────────────────┐
│                    OPTIMISTIC UPDATE FLOW                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                   │
│  User Click                                                       │
│      │                                                            │
│      ▼                                                            │
│  ┌──────────────────┐                                             │
│  │ Update UI        │ ◄── Instant (0ms)                          │
│  │ (optimistic)     │                                             │
│  └────────┬─────────┘                                             │
│           │                                                       │
│           ▼                                                       │
│  ┌──────────────────┐     ┌──────────────────┐                   │
│  │ Send API Request │────►│ Server Processing│ (200ms)           │
│  └────────┬─────────┘     └────────┬─────────┘                   │
│           │                        │                              │
│           ▼                        ▼                              │
│  ┌──────────────────┐     ┌──────────────────┐                   │
│  │ Success?         │     │ Return Response  │                   │
│  └────────┬─────────┘     └──────────────────┘                   │
│      ┌────┴────┐                                                  │
│      │         │                                                  │
│      ▼         ▼                                                  │
│   ┌─────┐  ┌─────────┐                                           │
│   │ Yes │  │ No      │                                           │
│   └──┬──┘  └────┬────┘                                           │
│      │          │                                                 │
│      ▼          ▼                                                 │
│  ┌────────┐  ┌──────────────┐                                    │
│  │ Confirm│  │ Rollback UI  │                                    │
│  │ State  │  │ Show Error   │                                    │
│  └────────┘  └──────────────┘                                    │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

### 2.2 Cart Store with Optimistic Updates (Zustand)

```typescript
// stores/cart-store.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import { toast } from 'sonner';

export interface CartItem {
  id: string;              // Cart line item ID
  variantId: string;
  productId: string;
  productName: string;
  productImage: string;
  variantName: string;     // "Red / XL"
  price: number;
  quantity: number;
  maxQuantity: number;     // Inventory limit
}

interface CartState {
  items: CartItem[];
  isOpen: boolean;
  isLoading: boolean;

  // Optimistic tracking
  pendingOperations: Map<string, 'add' | 'remove' | 'update'>;

  // Actions
  addItem: (item: Omit<CartItem, 'id'>) => Promise<void>;
  removeItem: (itemId: string) => Promise<void>;
  updateQuantity: (itemId: string, quantity: number) => Promise<void>;
  clearCart: () => void;

  // UI
  openCart: () => void;
  closeCart: () => void;

  // Computed
  totalItems: () => number;
  subtotal: () => number;
}

export const useCartStore = create<CartState>()(
  persist(
    immer((set, get) => ({
      items: [],
      isOpen: false,
      isLoading: false,
      pendingOperations: new Map(),

      addItem: async (newItem) => {
        const tempId = `temp-${Date.now()}`;
        const operationKey = `add-${newItem.variantId}`;

        // Check if variant already in cart
        const existingItem = get().items.find(
          item => item.variantId === newItem.variantId
        );

        // STEP 1: Optimistic Update (instant)
        set(state => {
          state.pendingOperations.set(operationKey, 'add');

          if (existingItem) {
            const item = state.items.find(i => i.id === existingItem.id);
            if (item && item.quantity < item.maxQuantity) {
              item.quantity += 1;
            }
          } else {
            state.items.push({ ...newItem, id: tempId });
          }
        });

        // Open cart drawer for feedback
        get().openCart();

        try {
          // STEP 2: Send to server
          const response = await fetch('/api/cart/add', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              variantId: newItem.variantId,
              quantity: 1,
            }),
          });

          if (!response.ok) {
            throw new Error('Failed to add item');
          }

          const data = await response.json();

          // STEP 3: Confirm with server response
          set(state => {
            state.pendingOperations.delete(operationKey);

            // Replace temp ID with real ID
            const item = state.items.find(
              i => i.id === tempId || i.variantId === newItem.variantId
            );
            if (item) {
              item.id = data.lineItemId;
              item.quantity = data.quantity;
            }
          });

          toast.success('Added to cart');

        } catch (error) {
          // STEP 4: Rollback on error
          set(state => {
            state.pendingOperations.delete(operationKey);

            if (existingItem) {
              // Revert quantity increment
              const item = state.items.find(i => i.id === existingItem.id);
              if (item) item.quantity -= 1;
            } else {
              // Remove optimistically added item
              state.items = state.items.filter(i => i.id !== tempId);
            }
          });

          toast.error('Failed to add item. Please try again.');
        }
      },

      removeItem: async (itemId) => {
        const operationKey = `remove-${itemId}`;
        const removedItem = get().items.find(i => i.id === itemId);
        const removedIndex = get().items.findIndex(i => i.id === itemId);

        if (!removedItem) return;

        // STEP 1: Optimistic removal
        set(state => {
          state.pendingOperations.set(operationKey, 'remove');
          state.items = state.items.filter(i => i.id !== itemId);
        });

        try {
          // STEP 2: Send to server
          const response = await fetch(`/api/cart/remove/${itemId}`, {
            method: 'DELETE',
          });

          if (!response.ok) throw new Error('Failed to remove item');

          // STEP 3: Confirm
          set(state => {
            state.pendingOperations.delete(operationKey);
          });

          toast.success('Item removed');

        } catch (error) {
          // STEP 4: Rollback
          set(state => {
            state.pendingOperations.delete(operationKey);
            // Re-insert at original position
            state.items.splice(removedIndex, 0, removedItem);
          });

          toast.error('Failed to remove item');
        }
      },

      updateQuantity: async (itemId, quantity) => {
        const operationKey = `update-${itemId}`;
        const item = get().items.find(i => i.id === itemId);
        const previousQuantity = item?.quantity ?? 0;

        if (!item || quantity < 1 || quantity > item.maxQuantity) return;

        // STEP 1: Optimistic update
        set(state => {
          state.pendingOperations.set(operationKey, 'update');
          const target = state.items.find(i => i.id === itemId);
          if (target) target.quantity = quantity;
        });

        try {
          // STEP 2: Send to server
          const response = await fetch(`/api/cart/update/${itemId}`, {
            method: 'PATCH',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ quantity }),
          });

          if (!response.ok) throw new Error('Failed to update quantity');

          // STEP 3: Confirm
          set(state => {
            state.pendingOperations.delete(operationKey);
          });

        } catch (error) {
          // STEP 4: Rollback
          set(state => {
            state.pendingOperations.delete(operationKey);
            const target = state.items.find(i => i.id === itemId);
            if (target) target.quantity = previousQuantity;
          });

          toast.error('Failed to update quantity');
        }
      },

      clearCart: () => set({ items: [] }),
      openCart: () => set({ isOpen: true }),
      closeCart: () => set({ isOpen: false }),

      totalItems: () => get().items.reduce((sum, item) => sum + item.quantity, 0),
      subtotal: () => get().items.reduce(
        (sum, item) => sum + item.price * item.quantity, 0
      ),
    })),
    {
      name: 'ecommerce-cart',
      partialize: (state) => ({ items: state.items }), // Only persist items
    }
  )
);
```

### 2.3 Add to Cart Button Component

```typescript
// components/product/AddToCartButton.tsx
'use client';

import { useState } from 'react';
import { useCartStore } from '@/stores/cart-store';
import { ProductVariant, Product } from '@/lib/product';
import { ShoppingBag, Check, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface AddToCartButtonProps {
  product: Product;
  selectedVariant: ProductVariant | null;
  selectedColorName: string;
  selectedSizeName: string;
}

export function AddToCartButton({
  product,
  selectedVariant,
  selectedColorName,
  selectedSizeName,
}: AddToCartButtonProps) {
  const addItem = useCartStore(state => state.addItem);
  const pendingOperations = useCartStore(state => state.pendingOperations);

  const [showSuccess, setShowSuccess] = useState(false);

  const isAdding = selectedVariant
    ? pendingOperations.has(`add-${selectedVariant.id}`)
    : false;

  const isDisabled = !selectedVariant || !selectedVariant.available || isAdding;

  const handleAddToCart = async () => {
    if (!selectedVariant) return;

    await addItem({
      variantId: selectedVariant.id,
      productId: product.id,
      productName: product.name,
      productImage: selectedVariant.images[0]?.url ?? product.images[0]?.url,
      variantName: `${selectedColorName} / ${selectedSizeName}`,
      price: selectedVariant.price,
      quantity: 1,
      maxQuantity: selectedVariant.inventory,
    });

    // Brief success state
    setShowSuccess(true);
    setTimeout(() => setShowSuccess(false), 2000);
  };

  return (
    <button
      onClick={handleAddToCart}
      disabled={isDisabled}
      className={cn(
        'w-full h-14 flex items-center justify-center gap-3',
        'text-base font-semibold rounded-lg transition-all duration-200',
        'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black',
        isDisabled
          ? 'bg-gray-200 text-gray-500 cursor-not-allowed'
          : showSuccess
            ? 'bg-green-600 text-white'
            : 'bg-black text-white hover:bg-gray-800 active:scale-[0.98]'
      )}
    >
      {isAdding ? (
        <>
          <Loader2 className="w-5 h-5 animate-spin" />
          Adding...
        </>
      ) : showSuccess ? (
        <>
          <Check className="w-5 h-5" />
          Added to Cart
        </>
      ) : !selectedVariant ? (
        'Select Size'
      ) : !selectedVariant.available ? (
        'Out of Stock'
      ) : (
        <>
          <ShoppingBag className="w-5 h-5" />
          Add to Cart — RM {selectedVariant.price.toFixed(2)}
        </>
      )}
    </button>
  );
}
```

### 2.4 Wishlist with Optimistic Toggle

```typescript
// stores/wishlist-store.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { toast } from 'sonner';

interface WishlistState {
  items: Set<string>;  // Product IDs
  pendingToggles: Set<string>;

  toggle: (productId: string) => Promise<void>;
  isInWishlist: (productId: string) => boolean;
  isPending: (productId: string) => boolean;
}

export const useWishlistStore = create<WishlistState>()(
  persist(
    (set, get) => ({
      items: new Set(),
      pendingToggles: new Set(),

      toggle: async (productId) => {
        const wasInWishlist = get().items.has(productId);

        // Optimistic toggle
        set(state => ({
          items: wasInWishlist
            ? new Set([...state.items].filter(id => id !== productId))
            : new Set([...state.items, productId]),
          pendingToggles: new Set([...state.pendingToggles, productId]),
        }));

        try {
          const response = await fetch('/api/wishlist', {
            method: wasInWishlist ? 'DELETE' : 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ productId }),
          });

          if (!response.ok) throw new Error();

          // Confirm
          set(state => ({
            pendingToggles: new Set(
              [...state.pendingToggles].filter(id => id !== productId)
            ),
          }));

          toast.success(wasInWishlist ? 'Removed from wishlist' : 'Added to wishlist');

        } catch {
          // Rollback
          set(state => ({
            items: wasInWishlist
              ? new Set([...state.items, productId])
              : new Set([...state.items].filter(id => id !== productId)),
            pendingToggles: new Set(
              [...state.pendingToggles].filter(id => id !== productId)
            ),
          }));

          toast.error('Failed to update wishlist');
        }
      },

      isInWishlist: (productId) => get().items.has(productId),
      isPending: (productId) => get().pendingToggles.has(productId),
    }),
    {
      name: 'ecommerce-wishlist',
      storage: {
        getItem: (name) => {
          const str = localStorage.getItem(name);
          if (!str) return null;
          const { state } = JSON.parse(str);
          return {
            state: {
              ...state,
              items: new Set(state.items),
              pendingToggles: new Set(),
            },
          };
        },
        setItem: (name, value) => {
          const serialized = {
            state: {
              ...value.state,
              items: [...value.state.items],
              pendingToggles: [],
            },
          };
          localStorage.setItem(name, JSON.stringify(serialized));
        },
        removeItem: (name) => localStorage.removeItem(name),
      },
    }
  )
);
```

```typescript
// components/product/WishlistButton.tsx
'use client';

import { useWishlistStore } from '@/stores/wishlist-store';
import { Heart, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface WishlistButtonProps {
  productId: string;
  variant?: 'icon' | 'full';
  className?: string;
}

export function WishlistButton({
  productId,
  variant = 'icon',
  className
}: WishlistButtonProps) {
  const { toggle, isInWishlist, isPending } = useWishlistStore();

  const inWishlist = isInWishlist(productId);
  const pending = isPending(productId);

  if (variant === 'icon') {
    return (
      <button
        onClick={() => toggle(productId)}
        disabled={pending}
        className={cn(
          'w-10 h-10 flex items-center justify-center rounded-full',
          'border border-gray-200 bg-white/90 backdrop-blur-sm',
          'transition-all duration-200 hover:border-gray-400',
          'focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2',
          className
        )}
        aria-label={inWishlist ? 'Remove from wishlist' : 'Add to wishlist'}
      >
        {pending ? (
          <Loader2 className="w-5 h-5 animate-spin text-gray-400" />
        ) : (
          <Heart
            className={cn(
              'w-5 h-5 transition-colors',
              inWishlist
                ? 'fill-red-500 text-red-500'
                : 'text-gray-600 hover:text-red-500'
            )}
          />
        )}
      </button>
    );
  }

  return (
    <button
      onClick={() => toggle(productId)}
      disabled={pending}
      className={cn(
        'h-14 px-6 flex items-center justify-center gap-2',
        'border-2 rounded-lg font-medium transition-all',
        inWishlist
          ? 'border-red-200 bg-red-50 text-red-600'
          : 'border-gray-200 text-gray-700 hover:border-gray-400',
        className
      )}
    >
      {pending ? (
        <Loader2 className="w-5 h-5 animate-spin" />
      ) : (
        <Heart className={cn('w-5 h-5', inWishlist && 'fill-current')} />
      )}
      {inWishlist ? 'In Wishlist' : 'Add to Wishlist'}
    </button>
  );
}
```

---

## Module 3: Visual Search & Filtering (PLP)

### 3.1 Fashion-First Filter Data Structure

```typescript
// types/filters.ts

export type FilterType = 'color' | 'size' | 'category' | 'price' | 'material' | 'style';

export interface ColorFilterOption {
  id: string;
  name: string;
  slug: string;
  hex: string;           // Primary color: "#C41E3A"
  gradient?: string;     // For multi-color: "linear-gradient(45deg, #C41E3A, #FFD700)"
  pattern?: string;      // Pattern image URL for prints
  count: number;         // Products with this color
}

export interface SizeFilterOption {
  id: string;
  name: string;          // "XS", "S", "M", "L", "XL", "XXL"
  slug: string;
  displayOrder: number;
  count: number;
}

export interface CategoryFilterOption {
  id: string;
  name: string;
  slug: string;
  thumbnail: string;     // Small category image
  count: number;
  children?: CategoryFilterOption[];
}

export interface PriceRange {
  min: number;
  max: number;
}

export interface FilterState {
  colors: string[];        // Selected color slugs
  sizes: string[];         // Selected size slugs
  categories: string[];    // Selected category slugs
  priceRange: PriceRange | null;
  materials: string[];
  styles: string[];
  sortBy: 'newest' | 'price-asc' | 'price-desc' | 'popular' | 'sale';
}

export interface FilterOptions {
  colors: ColorFilterOption[];
  sizes: SizeFilterOption[];
  categories: CategoryFilterOption[];
  priceRange: { min: number; max: number };
  materials: { id: string; name: string; slug: string; count: number }[];
  styles: { id: string; name: string; slug: string; count: number }[];
}

// URL serialization helpers
export const serializeFilters = (filters: FilterState): URLSearchParams => {
  const params = new URLSearchParams();

  if (filters.colors.length) params.set('color', filters.colors.join(','));
  if (filters.sizes.length) params.set('size', filters.sizes.join(','));
  if (filters.categories.length) params.set('category', filters.categories.join(','));
  if (filters.priceRange) {
    params.set('price', `${filters.priceRange.min}-${filters.priceRange.max}`);
  }
  if (filters.materials.length) params.set('material', filters.materials.join(','));
  if (filters.styles.length) params.set('style', filters.styles.join(','));
  if (filters.sortBy !== 'newest') params.set('sort', filters.sortBy);

  return params;
};

export const deserializeFilters = (params: URLSearchParams): FilterState => {
  const priceStr = params.get('price');
  let priceRange: PriceRange | null = null;

  if (priceStr) {
    const [min, max] = priceStr.split('-').map(Number);
    if (!isNaN(min) && !isNaN(max)) {
      priceRange = { min, max };
    }
  }

  return {
    colors: params.get('color')?.split(',').filter(Boolean) ?? [],
    sizes: params.get('size')?.split(',').filter(Boolean) ?? [],
    categories: params.get('category')?.split(',').filter(Boolean) ?? [],
    priceRange,
    materials: params.get('material')?.split(',').filter(Boolean) ?? [],
    styles: params.get('style')?.split(',').filter(Boolean) ?? [],
    sortBy: (params.get('sort') as FilterState['sortBy']) ?? 'newest',
  };
};
```

### 3.2 Visual Filter Components

```typescript
// components/filters/ColorFilter.tsx
'use client';

import { cn } from '@/lib/utils';
import { ColorFilterOption } from '@/types/filters';
import { Check } from 'lucide-react';

interface ColorFilterProps {
  options: ColorFilterOption[];
  selected: string[];
  onChange: (colors: string[]) => void;
}

export function ColorFilter({ options, selected, onChange }: ColorFilterProps) {
  const toggleColor = (slug: string) => {
    onChange(
      selected.includes(slug)
        ? selected.filter(s => s !== slug)
        : [...selected, slug]
    );
  };

  return (
    <div className="space-y-3">
      <h3 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">
        Color
      </h3>
      <div className="flex flex-wrap gap-2">
        {options.map((color) => {
          const isSelected = selected.includes(color.slug);

          return (
            <button
              key={color.id}
              onClick={() => toggleColor(color.slug)}
              className={cn(
                'group relative w-9 h-9 rounded-full transition-transform hover:scale-110',
                'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black',
                isSelected && 'ring-2 ring-black ring-offset-2'
              )}
              title={`${color.name} (${color.count})`}
              aria-pressed={isSelected}
            >
              {/* Color Swatch */}
              {color.pattern ? (
                <img
                  src={color.pattern}
                  alt={color.name}
                  className="w-full h-full rounded-full object-cover"
                />
              ) : color.gradient ? (
                <span
                  className="absolute inset-0 rounded-full"
                  style={{ background: color.gradient }}
                />
              ) : (
                <span
                  className="absolute inset-0 rounded-full border border-gray-200"
                  style={{ backgroundColor: color.hex }}
                />
              )}

              {/* Selected Checkmark */}
              {isSelected && (
                <span className="absolute inset-0 flex items-center justify-center">
                  <Check
                    className={cn(
                      'w-4 h-4',
                      // Contrast: white check on dark colors, black on light
                      isLightColor(color.hex) ? 'text-black' : 'text-white'
                    )}
                    strokeWidth={3}
                  />
                </span>
              )}

              {/* Tooltip */}
              <span className="absolute -bottom-8 left-1/2 -translate-x-1/2 px-2 py-1 text-xs font-medium bg-gray-900 text-white rounded opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none">
                {color.name}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

// Helper to determine if color is light (for checkmark contrast)
function isLightColor(hex: string): boolean {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance > 0.6;
}
```

```typescript
// components/filters/SizeFilter.tsx
'use client';

import { cn } from '@/lib/utils';
import { SizeFilterOption } from '@/types/filters';

interface SizeFilterProps {
  options: SizeFilterOption[];
  selected: string[];
  onChange: (sizes: string[]) => void;
}

export function SizeFilter({ options, selected, onChange }: SizeFilterProps) {
  const toggleSize = (slug: string) => {
    onChange(
      selected.includes(slug)
        ? selected.filter(s => s !== slug)
        : [...selected, slug]
    );
  };

  // Sort by display order
  const sortedOptions = [...options].sort((a, b) => a.displayOrder - b.displayOrder);

  return (
    <div className="space-y-3">
      <h3 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">
        Size
      </h3>
      <div className="flex flex-wrap gap-2">
        {sortedOptions.map((size) => {
          const isSelected = selected.includes(size.slug);
          const isAvailable = size.count > 0;

          return (
            <button
              key={size.id}
              onClick={() => isAvailable && toggleSize(size.slug)}
              disabled={!isAvailable}
              className={cn(
                'min-w-[2.75rem] h-11 px-3 rounded-full text-sm font-medium',
                'border-2 transition-all duration-150',
                'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black',
                isSelected
                  ? 'border-black bg-black text-white'
                  : isAvailable
                    ? 'border-gray-200 bg-white text-gray-900 hover:border-black'
                    : 'border-gray-100 bg-gray-50 text-gray-300 cursor-not-allowed'
              )}
              aria-pressed={isSelected}
            >
              {size.name}
            </button>
          );
        })}
      </div>
    </div>
  );
}
```

```typescript
// components/filters/CategoryFilter.tsx
'use client';

import { cn } from '@/lib/utils';
import { CategoryFilterOption } from '@/types/filters';
import Image from 'next/image';
import { Check } from 'lucide-react';

interface CategoryFilterProps {
  options: CategoryFilterOption[];
  selected: string[];
  onChange: (categories: string[]) => void;
}

export function CategoryFilter({ options, selected, onChange }: CategoryFilterProps) {
  const toggleCategory = (slug: string) => {
    onChange(
      selected.includes(slug)
        ? selected.filter(s => s !== slug)
        : [...selected, slug]
    );
  };

  return (
    <div className="space-y-3">
      <h3 className="text-sm font-semibold text-gray-900 uppercase tracking-wide">
        Category
      </h3>
      <div className="grid grid-cols-3 gap-2">
        {options.map((category) => {
          const isSelected = selected.includes(category.slug);

          return (
            <button
              key={category.id}
              onClick={() => toggleCategory(category.slug)}
              className={cn(
                'relative aspect-square rounded-lg overflow-hidden',
                'border-2 transition-all duration-150',
                'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black',
                isSelected ? 'border-black' : 'border-transparent hover:border-gray-300'
              )}
              aria-pressed={isSelected}
            >
              {/* Thumbnail */}
              <Image
                src={category.thumbnail}
                alt={category.name}
                fill
                className="object-cover"
                sizes="80px"
              />

              {/* Overlay with name */}
              <div className={cn(
                'absolute inset-0 flex items-end p-2',
                'bg-gradient-to-t from-black/60 to-transparent'
              )}>
                <span className="text-xs font-medium text-white truncate">
                  {category.name}
                </span>
              </div>

              {/* Selected indicator */}
              {isSelected && (
                <div className="absolute top-1 right-1 w-5 h-5 rounded-full bg-black flex items-center justify-center">
                  <Check className="w-3 h-3 text-white" strokeWidth={3} />
                </div>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
```

### 3.3 URL State Sync with Next.js Router

```typescript
// hooks/useFilterState.ts
'use client';

import { useCallback, useMemo, useTransition } from 'react';
import { useRouter, useSearchParams, usePathname } from 'next/navigation';
import {
  FilterState,
  serializeFilters,
  deserializeFilters,
  PriceRange
} from '@/types/filters';

export function useFilterState() {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const [isPending, startTransition] = useTransition();

  // Deserialize current filters from URL
  const filters = useMemo(
    () => deserializeFilters(searchParams),
    [searchParams]
  );

  // Update URL with new filters (debounced via startTransition)
  const setFilters = useCallback((newFilters: Partial<FilterState>) => {
    startTransition(() => {
      const merged = { ...filters, ...newFilters };
      const params = serializeFilters(merged);

      // Preserve scroll position on filter change
      router.push(`${pathname}?${params.toString()}`, { scroll: false });
    });
  }, [filters, pathname, router]);

  // Convenience methods for common operations
  const setColors = useCallback(
    (colors: string[]) => setFilters({ colors }),
    [setFilters]
  );

  const setSizes = useCallback(
    (sizes: string[]) => setFilters({ sizes }),
    [setFilters]
  );

  const setCategories = useCallback(
    (categories: string[]) => setFilters({ categories }),
    [setFilters]
  );

  const setPriceRange = useCallback(
    (priceRange: PriceRange | null) => setFilters({ priceRange }),
    [setFilters]
  );

  const setSortBy = useCallback(
    (sortBy: FilterState['sortBy']) => setFilters({ sortBy }),
    [setFilters]
  );

  const clearAll = useCallback(() => {
    startTransition(() => {
      router.push(pathname, { scroll: false });
    });
  }, [pathname, router]);

  const hasActiveFilters = useMemo(() => {
    return (
      filters.colors.length > 0 ||
      filters.sizes.length > 0 ||
      filters.categories.length > 0 ||
      filters.priceRange !== null ||
      filters.materials.length > 0 ||
      filters.styles.length > 0
    );
  }, [filters]);

  return {
    filters,
    setFilters,
    setColors,
    setSizes,
    setCategories,
    setPriceRange,
    setSortBy,
    clearAll,
    hasActiveFilters,
    isPending,
  };
}
```

### 3.4 Complete Filter Panel Component

```typescript
// components/filters/FilterPanel.tsx
'use client';

import { useState } from 'react';
import { FilterOptions } from '@/types/filters';
import { useFilterState } from '@/hooks/useFilterState';
import { ColorFilter } from './ColorFilter';
import { SizeFilter } from './SizeFilter';
import { CategoryFilter } from './CategoryFilter';
import { PriceRangeSlider } from './PriceRangeSlider';
import { X, SlidersHorizontal, ChevronDown, Loader2 } from 'lucide-react';
import { cn } from '@/lib/utils';

interface FilterPanelProps {
  options: FilterOptions;
  productCount: number;
}

export function FilterPanel({ options, productCount }: FilterPanelProps) {
  const {
    filters,
    setColors,
    setSizes,
    setCategories,
    setPriceRange,
    clearAll,
    hasActiveFilters,
    isPending,
  } = useFilterState();

  const [isOpen, setIsOpen] = useState(false);
  const [expandedSections, setExpandedSections] = useState<Set<string>>(
    new Set(['color', 'size'])
  );

  const toggleSection = (section: string) => {
    setExpandedSections(prev => {
      const next = new Set(prev);
      if (next.has(section)) next.delete(section);
      else next.add(section);
      return next;
    });
  };

  const activeFilterCount =
    filters.colors.length +
    filters.sizes.length +
    filters.categories.length +
    (filters.priceRange ? 1 : 0);

  return (
    <>
      {/* Mobile Filter Toggle */}
      <div className="lg:hidden sticky top-0 z-20 bg-white border-b border-gray-200 px-4 py-3">
        <div className="flex items-center justify-between">
          <button
            onClick={() => setIsOpen(true)}
            className="flex items-center gap-2 text-sm font-medium"
          >
            <SlidersHorizontal className="w-4 h-4" />
            Filters
            {activeFilterCount > 0 && (
              <span className="px-2 py-0.5 text-xs bg-black text-white rounded-full">
                {activeFilterCount}
              </span>
            )}
          </button>
          <span className="text-sm text-gray-500">
            {isPending ? (
              <Loader2 className="w-4 h-4 animate-spin" />
            ) : (
              `${productCount} products`
            )}
          </span>
        </div>
      </div>

      {/* Mobile Filter Drawer */}
      <div
        className={cn(
          'fixed inset-0 z-50 lg:hidden transition-opacity duration-300',
          isOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'
        )}
      >
        {/* Backdrop */}
        <div
          className="absolute inset-0 bg-black/50"
          onClick={() => setIsOpen(false)}
        />

        {/* Drawer */}
        <div
          className={cn(
            'absolute left-0 top-0 bottom-0 w-80 max-w-[85vw] bg-white',
            'transform transition-transform duration-300 ease-out',
            isOpen ? 'translate-x-0' : '-translate-x-full'
          )}
        >
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold">Filters</h2>
            <button
              onClick={() => setIsOpen(false)}
              className="p-2 -mr-2 hover:bg-gray-100 rounded-full"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          {/* Filter Content */}
          <div className="overflow-y-auto h-[calc(100vh-140px)] p-4 space-y-6">
            <FilterSection
              title="Color"
              isExpanded={expandedSections.has('color')}
              onToggle={() => toggleSection('color')}
            >
              <ColorFilter
                options={options.colors}
                selected={filters.colors}
                onChange={setColors}
              />
            </FilterSection>

            <FilterSection
              title="Size"
              isExpanded={expandedSections.has('size')}
              onToggle={() => toggleSection('size')}
            >
              <SizeFilter
                options={options.sizes}
                selected={filters.sizes}
                onChange={setSizes}
              />
            </FilterSection>

            <FilterSection
              title="Category"
              isExpanded={expandedSections.has('category')}
              onToggle={() => toggleSection('category')}
            >
              <CategoryFilter
                options={options.categories}
                selected={filters.categories}
                onChange={setCategories}
              />
            </FilterSection>

            <FilterSection
              title="Price"
              isExpanded={expandedSections.has('price')}
              onToggle={() => toggleSection('price')}
            >
              <PriceRangeSlider
                min={options.priceRange.min}
                max={options.priceRange.max}
                value={filters.priceRange}
                onChange={setPriceRange}
              />
            </FilterSection>
          </div>

          {/* Footer */}
          <div className="absolute bottom-0 left-0 right-0 px-4 py-4 bg-white border-t border-gray-200">
            <div className="flex gap-3">
              {hasActiveFilters && (
                <button
                  onClick={clearAll}
                  className="flex-1 h-12 border border-gray-300 rounded-lg font-medium hover:bg-gray-50"
                >
                  Clear All
                </button>
              )}
              <button
                onClick={() => setIsOpen(false)}
                className="flex-1 h-12 bg-black text-white rounded-lg font-medium"
              >
                Show {productCount} Results
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Desktop Sidebar */}
      <aside className="hidden lg:block w-64 flex-shrink-0 space-y-6">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold">Filters</h2>
          {hasActiveFilters && (
            <button
              onClick={clearAll}
              className="text-sm text-gray-500 hover:text-black underline"
            >
              Clear all
            </button>
          )}
        </div>

        <ColorFilter
          options={options.colors}
          selected={filters.colors}
          onChange={setColors}
        />

        <SizeFilter
          options={options.sizes}
          selected={filters.sizes}
          onChange={setSizes}
        />

        <CategoryFilter
          options={options.categories}
          selected={filters.categories}
          onChange={setCategories}
        />

        <PriceRangeSlider
          min={options.priceRange.min}
          max={options.priceRange.max}
          value={filters.priceRange}
          onChange={setPriceRange}
        />

        {isPending && (
          <div className="flex items-center gap-2 text-sm text-gray-500">
            <Loader2 className="w-4 h-4 animate-spin" />
            Updating...
          </div>
        )}
      </aside>
    </>
  );
}

function FilterSection({
  title,
  isExpanded,
  onToggle,
  children
}: {
  title: string;
  isExpanded: boolean;
  onToggle: () => void;
  children: React.ReactNode;
}) {
  return (
    <div className="border-b border-gray-200 pb-4">
      <button
        onClick={onToggle}
        className="flex items-center justify-between w-full py-2"
      >
        <span className="text-sm font-semibold uppercase tracking-wide">
          {title}
        </span>
        <ChevronDown
          className={cn(
            'w-4 h-4 transition-transform',
            isExpanded && 'rotate-180'
          )}
        />
      </button>
      {isExpanded && <div className="pt-3">{children}</div>}
    </div>
  );
}
```

---

## Folder Structure

```
frontend-store/
├── app/
│   ├── (shop)/
│   │   ├── layout.tsx              # Shop layout with header/footer
│   │   ├── page.tsx                # Homepage
│   │   ├── collections/
│   │   │   └── [slug]/
│   │   │       └── page.tsx        # PLP (Server Component)
│   │   └── products/
│   │       └── [slug]/
│   │           └── page.tsx        # PDP (Server Component)
│   ├── cart/
│   │   └── page.tsx                # Cart page
│   ├── checkout/
│   │   └── page.tsx                # Checkout flow
│   └── layout.tsx                  # Root layout
│
├── components/
│   ├── cart/
│   │   ├── CartDrawer.tsx          # Slide-out cart
│   │   ├── CartItem.tsx
│   │   └── CartSummary.tsx
│   │
│   ├── filters/
│   │   ├── FilterPanel.tsx         # Main filter container
│   │   ├── ColorFilter.tsx         # Visual color swatches
│   │   ├── SizeFilter.tsx          # Circular size buttons
│   │   ├── CategoryFilter.tsx      # Thumbnail categories
│   │   ├── PriceRangeSlider.tsx
│   │   └── ActiveFilters.tsx       # Selected filter chips
│   │
│   ├── product/
│   │   ├── ProductCard.tsx         # PLP card
│   │   ├── ProductGallery.tsx      # Image gallery with zoom
│   │   ├── VariantSelector.tsx     # Color + Size selection
│   │   ├── AddToCartButton.tsx     # Optimistic add to cart
│   │   ├── WishlistButton.tsx      # Optimistic wishlist toggle
│   │   └── ProductTabs.tsx         # Description, Size Guide, Reviews
│   │
│   ├── layout/
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   ├── Navigation.tsx
│   │   └── MobileMenu.tsx
│   │
│   └── ui/                         # Shared UI components
│       ├── Button.tsx
│       ├── Badge.tsx
│       └── Skeleton.tsx
│
├── hooks/
│   ├── useFilterState.ts           # URL-synced filter state
│   ├── useDebounce.ts
│   └── useMediaQuery.ts
│
├── lib/
│   ├── api/
│   │   ├── products.ts             # Product API calls
│   │   ├── cart.ts                 # Cart API calls
│   │   └── wishlist.ts             # Wishlist API calls
│   │
│   ├── product/
│   │   ├── variant-matrix.ts       # Variant lookup utilities
│   │   └── index.ts
│   │
│   └── utils.ts                    # cn(), formatPrice(), etc.
│
├── stores/
│   ├── cart-store.ts               # Zustand cart with optimistic updates
│   ├── wishlist-store.ts           # Zustand wishlist
│   └── recently-viewed-store.ts
│
├── types/
│   ├── product.ts                  # Product, Variant, Color, Size types
│   ├── filters.ts                  # Filter types and serialization
│   └── cart.ts                     # Cart types
│
└── styles/
    └── globals.css                 # Tailwind + custom CSS
```

---

## API Contract Summary

### Products API

```typescript
// GET /api/products/:slug
interface ProductResponse {
  product: Product;
  relatedProducts: ProductCard[];
}

// GET /api/collections/:slug/products
interface CollectionProductsRequest {
  color?: string;        // Comma-separated slugs
  size?: string;         // Comma-separated slugs
  category?: string;     // Comma-separated slugs
  price?: string;        // "min-max" format
  sort?: 'newest' | 'price-asc' | 'price-desc' | 'popular' | 'sale';
  page?: number;
  limit?: number;
}

interface CollectionProductsResponse {
  products: ProductCard[];
  total: number;
  page: number;
  totalPages: number;
  filterOptions: FilterOptions;  // Dynamic based on available products
}
```

### Cart API

```typescript
// POST /api/cart/add
interface AddToCartRequest {
  variantId: string;
  quantity: number;
}

interface AddToCartResponse {
  lineItemId: string;
  quantity: number;
  cartTotal: number;
}

// PATCH /api/cart/update/:lineItemId
interface UpdateCartRequest {
  quantity: number;
}

// DELETE /api/cart/remove/:lineItemId
// Returns 204 No Content
```

---

## Performance Targets

| Metric | Target | Strategy |
|--------|--------|----------|
| LCP | < 2.5s | Server Components, Image optimization |
| FID | < 100ms | Minimal client JS, code splitting |
| CLS | < 0.1 | Reserved image dimensions, skeleton loaders |
| TTI | < 3.5s | Progressive hydration, streaming |

---

## Next Steps

1. **Set up Next.js 14 project** with TypeScript and Tailwind
2. **Implement core types** from this spec
3. **Build variant matrix utilities** with unit tests
4. **Create filter components** with Storybook stories
5. **Integrate with backend APIs** from Go microservices
6. **Add E2E tests** with Playwright

---

*Generated for E-commerce Platform - Fashion eCommerce Platform*
