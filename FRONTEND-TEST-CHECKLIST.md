# Frontend Testing Checklist

Complete UI testing guide for all frontend applications.

---

## Admin Dashboard (`frontend-admin`)

### Login Page (`/login`)
- [ ] Login form renders correctly
- [ ] Validation shows for empty fields
- [ ] Invalid credentials show error message
- [ ] Successful login redirects to dashboard
- [ ] Token stored in cookies/localStorage

### Dashboard (`/dashboard`)
- [ ] Stats cards display (Sales, Orders, Products, Customers)
- [ ] Charts render with data
- [ ] Recent orders table loads
- [ ] All navigation links work

### Products (`/products`)
- [ ] Products list loads with pagination
- [ ] Search filter works
- [ ] "Add Product" button opens form
- [ ] Product creation saves successfully
- [ ] Edit product works
- [ ] Delete product with confirmation

### Categories (`/categories`)
- [ ] Category list renders
- [ ] Create new category works
- [ ] Edit category works
- [ ] Category hierarchy displays

### Orders (`/orders`)
- [ ] Orders list with filters
- [ ] Order status filter works
- [ ] View order details
- [ ] Update order status
- [ ] Order timeline displays

### Customers (`/customers`)
- [ ] Customer list loads
- [ ] Search works
- [ ] View customer details
- [ ] Customer order history shows

### Inventory (`/inventory`)
- [ ] Stock levels display
- [ ] Low stock alerts show
- [ ] Stock adjustment works

### Team/Users (`/team`)
- [ ] User list displays
- [ ] Role assignment works
- [ ] User creation works
- [ ] Permission verification

### Settings (`/settings`)
- [ ] Settings panels render
- [ ] Settings save correctly

---

## Storefront (`frontend-storefront`)

### Home Page (`/`)
- [ ] Hero banner displays
- [ ] Featured products load
- [ ] Category navigation works
- [ ] Footer links work

### Products (`/products`)
- [ ] Product grid renders
- [ ] Filters work (category, price)
- [ ] Search works
- [ ] Pagination works

### Product Detail (`/products/:id`)
- [ ] Product info displays
- [ ] Images gallery works
- [ ] Variant selection works
- [ ] Add to cart works
- [ ] Reviews display

### Cart (`/cart`)
- [ ] Cart items display
- [ ] Quantity update works
- [ ] Remove item works
- [ ] Subtotal calculates correctly
- [ ] Proceed to checkout works

### Checkout (`/checkout`)
- [ ] Address form works
- [ ] Payment options display
- [ ] Order summary shows
- [ ] Place order works
- [ ] Order confirmation page

### Account (`/account`)
- [ ] Profile displays
- [ ] Order history loads
- [ ] Address management works

---

## Warehouse Portal (`frontend-warehouse`)

### Dashboard
- [ ] Pending orders count
- [ ] Low stock alerts
- [ ] Quick actions work

### Order Picking
- [ ] Pick list displays
- [ ] Item scanning/checking works
- [ ] Complete picking works

### Receiving
- [ ] Receive stock form
- [ ] Quantity adjustment
- [ ] Confirm receipt

### Transfers
- [ ] Transfer list
- [ ] Create transfer
- [ ] Receive transfer

---

## Cross-Cutting Tests

### Authentication
- [ ] Login works in all apps
- [ ] Logout clears session
- [ ] Unauthorized redirect works
- [ ] Token refresh works

### Responsiveness
- [ ] Admin: Desktop, Tablet
- [ ] Storefront: Desktop, Tablet, Mobile
- [ ] Warehouse: Tablet, Mobile (PWA)

### API Integration
- [ ] All API calls use correct endpoints
- [ ] Error handling displays messages
- [ ] Loading states show

### RBAC (Admin)
- [ ] SUPER_ADMIN sees all menus
- [ ] STAFF_ORDERS only sees orders
- [ ] STAFF_PRODUCTS only sees products
- [ ] Unauthorized pages show 403

---

## Test Status

| App | Tested | Issues |
|-----|--------|--------|
| frontend-admin | ☐ | - |
| frontend-storefront | ☐ | - |
| frontend-warehouse | ☐ | - |

**Tester**: ________________  
**Date**: ________________
