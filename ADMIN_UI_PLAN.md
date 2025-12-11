# Admin UI Development Plan

## Overview

Complete admin dashboard for managing the Kilang Desa Murni Batik e-commerce platform. Built with Next.js 14, TypeScript, Tailwind CSS, and shadcn/ui.

---

## Technology Stack

**Frontend Framework**: Next.js 14 (App Router)
**Language**: TypeScript
**Styling**: Tailwind CSS
**UI Components**: shadcn/ui
**State Management**: React Query / TanStack Query
**Forms**: React Hook Form + Zod validation
**Tables**: TanStack Table
**Charts**: Recharts
**Icons**: Lucide React

---

## Admin UI Modules

### 1. Product Management Screens

#### 1.1 Product List Page
**Route**: `/admin/products`

**Features**:
- Searchable product table
- Filter by: category, status, stock level
- Sort by: name, price, stock, created date
- Bulk actions: activate, deactivate, delete
- Quick actions: edit, duplicate, view

**Components**:
- `ProductsTable` - Main data table
- `ProductFilters` - Filter sidebar
- `ProductSearchBar` - Search input
- `BulkActionMenu` - Bulk operation dropdown
- `ProductQuickActions` - Row action buttons

**API Endpoints**:
```
GET /api/v1/products?page=1&limit=20&search=&category=&status=
DELETE /api/v1/products/bulk
PATCH /api/v1/products/bulk/status
```

---

#### 1.2 Product Create/Edit Page
**Route**: `/admin/products/new` or `/admin/products/[id]/edit`

**Sections**:
1. **Basic Information**
   - Product name
   - SKU
   - Description (rich text editor)
   - Product type (batik fabric, ready-made, accessories)
   - Category selection

2. **Pricing**
   - Base price
   - Compare at price (for sales)
   - Cost price (for profit calculation)
   - Tax settings

3. **Inventory**
   - Track inventory toggle
   - SKU
   - Barcode
   - Stock quantity
   - Low stock threshold

4. **Batik-Specific Fields**
   - Unit type (meter, piece)
   - Minimum order quantity
   - Fabric width
   - Fabric composition
   - Is tailorable toggle

5. **Variants**
   - Option types (size, color, length)
   - Variant combinations
   - Per-variant pricing
   - Per-variant inventory

6. **Media**
   - Image upload (drag & drop)
   - Image reordering
   - Alt text
   - Video upload (optional)

7. **Organization**
   - Collections
   - Tags
   - Vendor

8. **SEO**
   - Meta title
   - Meta description
   - URL handle

**Components**:
- `ProductForm` - Main form container
- `BasicInfoSection` - Name, description, type
- `PricingSection` - Pricing fields
- `InventorySection` - Stock management
- `VariantsSection` - Variant builder
- `MediaSection` - Image/video upload
- `SEOSection` - Meta information

**Validation**:
```typescript
const productSchema = z.object({
  name: z.string().min(1, "Product name required"),
  sku: z.string().min(1, "SKU required"),
  price: z.number().min(0, "Price must be positive"),
  // ... etc
})
```

---

### 2. Order Management Interface

#### 2.1 Order List Page
**Route**: `/admin/orders`

**Features**:
- Real-time order list
- Filter by: status, payment status, date range, agent
- Search by: order number, customer name, email
- Status badges with colors
- Quick status update
- Export orders (CSV, Excel)

**Filters**:
- All orders
- Pending
- Confirmed
- Processing
- Shipped
- Delivered
- Cancelled

**Components**:
- `OrdersTable` - Main table with pagination
- `OrderFilters` - Filter sidebar
- `OrderStatusBadge` - Status indicator
- `OrderQuickActions` - Quick action menu
- `OrderExportButton` - Export dropdown

**API Endpoints**:
```
GET /api/v1/orders?page=1&status=&payment_status=&date_from=&date_to=
GET /api/v1/orders/export?format=csv
```

---

#### 2.2 Order Detail Page
**Route**: `/admin/orders/[id]`

**Sections**:
1. **Order Summary**
   - Order number
   - Date & time
   - Current status
   - Payment status
   - Status timeline

2. **Customer Information**
   - Customer name & email
   - Phone number
   - Order history link
   - Notes section

3. **Order Items**
   - Product list with images
   - Quantity & price
   - Variant details
   - Subtotal calculation

4. **Pricing Breakdown**
   - Subtotal
   - Shipping cost
   - Discounts applied
   - Tax
   - Total

5. **Shipping Address**
   - Full address
   - Map preview (Google Maps)
   - Copy address button

6. **Fulfillment**
   - Fulfillment status
   - Warehouse location
   - Tracking number
   - Carrier information
   - Mark as fulfilled button

7. **Payment**
   - Payment method
   - Payment receipt (if uploaded)
   - Payment verification status
   - Approve/reject buttons

8. **Refunds** (if any)
   - Refund amount
   - Refund reason
   - Refund status

9. **Timeline/Activity**
   - Order created
   - Payment received
   - Order confirmed
   - Shipped
   - Delivered
   - All status changes with timestamps

10. **Actions**
    - Edit order
    - Cancel order
    - Create refund
    - Resend confirmation email
    - Print invoice
    - Print packing slip

**Components**:
- `OrderDetailHeader` - Order number & status
- `OrderTimeline` - Status history
- `CustomerCard` - Customer info
- `OrderItemsTable` - Items list
- `PricingBreakdown` - Cost summary
- `ShippingCard` - Address & tracking
- `FulfillmentSection` - Fulfillment management
- `PaymentSection` - Payment verification
- `OrderActions` - Action buttons

---

### 3. Customer Management Pages

#### 3.1 Customer List Page
**Route**: `/admin/customers`

**Features**:
- Customer table with stats
- Filter by: segment, orders count, total spent
- Search by: name, email, phone
- Customer segments (VIP, New, Repeat, At Risk)
- Export customers

**Columns**:
- Name
- Email
- Phone
- Total Orders
- Total Spent
- Last Order Date
- Segment
- Actions

**Components**:
- `CustomersTable` - Main table
- `CustomerFilters` - Segment filters
- `CustomerSearchBar` - Search input
- `CustomerSegmentBadge` - Segment indicator
- `CustomerQuickActions` - Edit/view/delete

**API Endpoints**:
```
GET /api/v1/customers?page=1&segment=&search=&sort=total_spent
GET /api/v1/customers/export
```

---

#### 3.2 Customer Detail Page
**Route**: `/admin/customers/[id]`

**Sections**:
1. **Customer Profile**
   - Name, email, phone
   - Customer since date
   - Segments
   - Tags
   - Edit profile button

2. **Statistics**
   - Total orders
   - Total spent
   - Average order value
   - Last order date

3. **Order History**
   - List of all orders
   - Order number, date, total, status
   - Link to order details

4. **Addresses**
   - Shipping addresses
   - Billing addresses
   - Default address indicators
   - Add/edit/delete

5. **Notes**
   - Staff notes about customer
   - Note type (general, support, VIP, warning)
   - Add note button
   - Note history

6. **Activity**
   - Login history
   - Order activity
   - Profile updates
   - Account creation

**Components**:
- `CustomerProfileCard` - Profile info
- `CustomerStatsCards` - Statistics
- `CustomerOrderHistory` - Orders table
- `CustomerAddresses` - Address list
- `CustomerNotes` - Notes section
- `CustomerActivity` - Activity timeline

---

### 4. Inventory Dashboard

#### 4.1 Inventory Overview
**Route**: `/admin/inventory`

**Sections**:
1. **Summary Cards**
   - Total products
   - Low stock items
   - Out of stock items
   - Total inventory value

2. **Warehouse Overview**
   - Stock per warehouse
   - Available vs reserved
   - Low stock alerts

3. **Recent Movements**
   - Latest stock changes
   - Movement type (sale, transfer, adjustment)
   - Quantity changed
   - Reference (order number)

4. **Low Stock Alerts**
   - Products below threshold
   - Current quantity
   - Recommended reorder quantity
   - Quick restock action

**Components**:
- `InventorySummaryCards` - KPI cards
- `WarehouseStockChart` - Bar chart
- `RecentMovementsTable` - Movement history
- `LowStockAlertsTable` - Alert list

**API Endpoints**:
```
GET /api/v1/inventory/summary
GET /api/v1/inventory/warehouses
GET /api/v1/inventory/movements?limit=20
GET /api/v1/inventory/low-stock
```

---

#### 4.2 Stock Transfers
**Route**: `/admin/inventory/transfers`

**Features**:
- Create transfer between warehouses
- Transfer status tracking
- Pending transfers list
- Transfer history

**Transfer Form**:
- Source warehouse
- Destination warehouse
- Products to transfer
- Quantity per product
- Transfer notes
- Expected arrival date

**Components**:
- `TransfersList` - Transfers table
- `CreateTransferForm` - New transfer form
- `TransferStatusBadge` - Status indicator
- `TransferDetail` - Transfer details view

---

### 5. Discount Configuration UI

#### 5.1 Discount List Page
**Route**: `/admin/discounts`

**Features**:
- Active/scheduled/expired discounts
- Filter by: type, status, date range
- Search by: code, title
- Duplicate discount
- Archive discount

**Columns**:
- Title
- Code (or "Automatic")
- Type
- Value
- Status
- Usage (count/limit)
- Start/End Date
- Actions

**Components**:
- `DiscountsTable` - Main table
- `DiscountFilters` - Filter sidebar
- `DiscountStatusBadge` - Status indicator
- `DiscountTypeIcon` - Type icon
- `DiscountQuickActions` - Actions menu

---

#### 5.2 Discount Create/Edit Page
**Route**: `/admin/discounts/new` or `/admin/discounts/[id]/edit`

**Sections**:
1. **Basic Information**
   - Title
   - Discount code (optional for automatic)
   - Description

2. **Type & Value**
   - Discount type selector
   - Value input (percentage or fixed)
   - Free shipping toggle

3. **Applies To**
   - Scope selector (all, products, collections, customers)
   - Product/collection picker
   - Customer picker

4. **Requirements**
   - Minimum purchase amount
   - Minimum quantity
   - Eligible items count

5. **Customer Eligibility**
   - All customers
   - Specific customers
   - Customer segments

6. **Usage Limits**
   - Total usage limit
   - One per customer toggle
   - Current usage count (edit mode)

7. **Active Dates**
   - Start date & time
   - End date & time (optional)
   - Set as active toggle

8. **Buy X Get Y** (if BXGY type selected)
   - Buy quantity
   - Buy products
   - Get quantity
   - Get products
   - Discount percentage

**Components**:
- `DiscountForm` - Main form
- `DiscountTypeSelector` - Type picker
- `ScopeSelector` - Applies to picker
- `ProductPicker` - Product selection modal
- `CustomerPicker` - Customer selection modal
- `BXGYConfiguration` - BXGY settings
- `DateRangePicker` - Date selection

---

### 6. Reports and Analytics

#### 6.1 Dashboard Overview
**Route**: `/admin/dashboard`

**Widgets**:
1. **Sales Overview**
   - Total sales (today, week, month, year)
   - Sales trend chart
   - Comparison to previous period

2. **Order Statistics**
   - Total orders
   - Pending orders
   - Fulfillment rate
   - Average order value

3. **Revenue Metrics**
   - Total revenue
   - Revenue by category
   - Top products
   - Top customers

4. **Performance Indicators**
   - Conversion rate
   - Cart abandonment rate
   - Customer acquisition cost
   - Customer lifetime value

5. **Recent Orders**
   - Latest 10 orders
   - Quick status view
   - Link to full order

6. **Low Stock Alerts**
   - Products running low
   - Quick restock links

7. **Agent Performance** (if applicable)
   - Top agents by sales
   - Commission pending
   - Recent agent orders

**Components**:
- `SalesOverviewCard` - Sales stats
- `SalesChart` - Line/bar chart
- `OrderStatsCards` - Order metrics
- `RevenueBreakdown` - Pie chart
- `RecentOrdersWidget` - Orders list
- `LowStockWidget` - Stock alerts
- `TopProductsWidget` - Product ranking
- `AgentPerformanceWidget` - Agent stats

---

#### 6.2 Sales Reports
**Route**: `/admin/reports/sales`

**Features**:
- Date range selector
- Sales summary report
- Sales by product
- Sales by category
- Sales by agent
- Export reports (PDF, CSV)

**Filters**:
- Date range (today, week, month, year, custom)
- Product filter
- Category filter
- Agent filter
- Payment method filter

**Charts**:
- Sales trend over time (line chart)
- Sales by category (pie chart)
- Sales by hour/day (bar chart)
- Sales by payment method (donut chart)

**Tables**:
- Top selling products
- Sales by category
- Sales by agent
- Daily/weekly/monthly breakdown

**Components**:
- `SalesReportFilters` - Filter controls
- `SalesReportSummary` - Summary cards
- `SalesTrendChart` - Time series chart
- `CategoryBreakdownChart` - Pie chart
- `TopProductsTable` - Product ranking
- `ReportExportButton` - Export options

---

#### 6.3 Customer Reports
**Route**: `/admin/reports/customers`

**Features**:
- New customers trend
- Customer segments breakdown
- Customer lifetime value
- Repeat customer rate
- Customer acquisition sources

**Reports**:
- Customer growth chart
- Segment distribution
- Top customers by revenue
- Customer retention rate
- Average order frequency

---

#### 6.4 Inventory Reports
**Route**: `/admin/reports/inventory`

**Features**:
- Stock levels by warehouse
- Inventory turnover rate
- Dead stock analysis
- Stock movement history
- Reorder recommendations

**Reports**:
- Stock value by warehouse
- Fast moving vs slow moving
- Stock aging analysis
- Warehouse utilization

---

## Common UI Patterns

### Navigation

**Sidebar Navigation**:
```
Dashboard
├── Overview

Products
├── All Products
├── Add Product
├── Categories
├── Collections

Orders
├── All Orders
├── Pending
├── Processing
├── Fulfilled

Customers
├── All Customers
├── Segments
├── Customer Groups

Inventory
├── Overview
├── Warehouses
├── Transfers
├── Adjustments

Discounts
├── All Discounts
├── Create Discount

Reports
├── Sales
├── Customers
├── Inventory
├── Analytics

Agents (if applicable)
├── All Agents
├── Commissions
├── Performance

Settings
├── General
├── Shipping
├── Payments
├── Taxes
└── Users
```

---

### Data Tables

**Standard Features**:
- Pagination
- Sorting
- Filtering
- Search
- Column visibility toggle
- Row selection
- Bulk actions
- Export

**Using TanStack Table**:
```typescript
const table = useReactTable({
  data,
  columns,
  getCoreRowModel: getCoreRowModel(),
  getPaginationRowModel: getPaginationRowModel(),
  getSortedRowModel: getSortedRowModel(),
  getFilteredRowModel: getFilteredRowModel(),
})
```

---

### Forms

**Standard Features**:
- Validation (Zod)
- Error messages
- Loading states
- Auto-save (drafts)
- Dirty state tracking
- Confirmation on exit

**Using React Hook Form**:
```typescript
const form = useForm<FormData>({
  resolver: zodResolver(schema),
  defaultValues,
})
```

---

### Modals/Dialogs

**Common Modals**:
- Confirmation dialogs
- Delete confirmations
- Quick edit forms
- Image preview
- Product picker
- Customer picker
- Date picker

**Using shadcn Dialog**:
```typescript
<Dialog>
  <DialogTrigger>Open</DialogTrigger>
  <DialogContent>
    <DialogHeader>
      <DialogTitle>Title</DialogTitle>
    </DialogHeader>
    {/* Content */}
  </DialogContent>
</Dialog>
```

---

### Notifications

**Toast Notifications**:
- Success messages
- Error messages
- Warning messages
- Info messages
- Loading indicators

**Using shadcn Toast**:
```typescript
toast({
  title: "Success",
  description: "Product created successfully",
  variant: "success",
})
```

---

## State Management

### API Integration

**Using React Query**:
```typescript
// Fetch data
const { data, isLoading, error } = useQuery({
  queryKey: ['products', filters],
  queryFn: () => fetchProducts(filters),
})

// Mutations
const mutation = useMutation({
  mutationFn: createProduct,
  onSuccess: () => {
    queryClient.invalidateQueries(['products'])
    toast({ title: "Product created" })
  },
})
```

---

### Form State

**Using React Hook Form + Zod**:
```typescript
const schema = z.object({
  name: z.string().min(1),
  price: z.number().min(0),
})

const form = useForm({
  resolver: zodResolver(schema),
})

const onSubmit = form.handleSubmit((data) => {
  mutation.mutate(data)
})
```

---

## Authentication & Authorization

### Protected Routes

```typescript
// middleware.ts
export function middleware(request: NextRequest) {
  const token = request.cookies.get('auth_token')

  if (!token && request.nextUrl.pathname.startsWith('/admin')) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
}
```

### Role-Based Access

```typescript
// Check user permissions
const { user } = useAuth()

if (!user.hasPermission('products:create')) {
  return <Forbidden />
}
```

---

## Performance Optimization

### Best Practices

1. **Code Splitting**
   - Lazy load routes
   - Dynamic imports for heavy components

2. **Caching**
   - React Query cache
   - SWR for real-time data
   - Local storage for preferences

3. **Image Optimization**
   - Next.js Image component
   - WebP format
   - Lazy loading

4. **Data Fetching**
   - Pagination
   - Virtual scrolling for large lists
   - Debounced search

5. **Bundle Size**
   - Tree shaking
   - Dynamic imports
   - Analyze bundle (next/bundle-analyzer)

---

## Testing Strategy

### Unit Tests
- Components (React Testing Library)
- Utilities (Jest)
- Hooks (React Hooks Testing Library)

### Integration Tests
- API integration
- Form submissions
- Navigation flows

### E2E Tests
- Critical user flows (Playwright)
- Order creation
- Product management
- Customer management

---

## Deployment

### Build Process
```bash
npm run build
npm run start
```

### Environment Variables
```env
NEXT_PUBLIC_API_URL=https://api.kilangdesa.com
NEXT_PUBLIC_MINIO_URL=https://storage.kilangdesa.com
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=xxx
```

---

## Next Steps

### Phase 1: Foundation (Week 1-2)
- [ ] Project setup (Next.js 14, TypeScript, Tailwind)
- [ ] Install shadcn/ui components
- [ ] Setup authentication
- [ ] Create layout & navigation
- [ ] Setup API client (Axios/Fetch with React Query)

### Phase 2: Core Features (Week 3-5)
- [ ] Product management (list, create, edit)
- [ ] Order management (list, detail, status updates)
- [ ] Customer management (list, detail)
- [ ] Basic inventory dashboard

### Phase 3: Advanced Features (Week 6-8)
- [ ] Discount configuration
- [ ] Inventory transfers
- [ ] Reports & analytics
- [ ] Agent management (if applicable)

### Phase 4: Polish & Testing (Week 9-10)
- [ ] UI/UX refinements
- [ ] Performance optimization
- [ ] Testing (unit, integration, E2E)
- [ ] Documentation

---

**Last Updated**: 2025-12-09
**Version**: 1.0.0
