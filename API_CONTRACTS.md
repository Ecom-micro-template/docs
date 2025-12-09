# Kilang Desa Murni Batik - API Contracts

API contract documentation for all microservices.

## Base URLs

| Service | Development | Production |
|---------|-------------|------------|
| Auth | `http://localhost:8081/api/v1` | `/api/v1` |
| Catalog | `http://localhost:8082/api/v1` | `/api/v1` |
| Order | `http://localhost:8083/api/v1` | `/api/v1` |
| Customer | `http://localhost:8084/api/v1` | `/api/v1` |
| Inventory | `http://localhost:8085/api/v1` | `/api/v1` |
| Reporting | `http://localhost:8086/api/v1` | `/api/v1` |

---

## Authentication Service (`service-auth`)

### Auth Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/auth/register` | Register new user | Public |
| POST | `/auth/login` | Login user | Public |
| POST | `/auth/logout` | Logout user | Bearer |
| GET | `/auth/me` | Get current user with roles/permissions | Bearer |
| POST | `/auth/refresh` | Refresh access token | Bearer |
| POST | `/auth/forgot-password` | Request password reset | Public |
| POST | `/auth/reset-password` | Reset password | Public |

### User Management

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/users` | List users (paginated) | `users.view` |
| GET | `/admin/users/:id` | Get user by ID | `users.view` |
| POST | `/admin/users` | Create user | `users.create` |
| PUT | `/admin/users/:id` | Update user | `users.update` |
| DELETE | `/admin/users/:id` | Delete user | `users.delete` |

### Role Management

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/roles` | List roles | `roles.view` |
| GET | `/admin/roles/:id` | Get role with permissions | `roles.view` |
| POST | `/admin/roles` | Create role | `roles.create` |
| PUT | `/admin/roles/:id` | Update role | `roles.update` |
| DELETE | `/admin/roles/:id` | Delete role | `roles.delete` |
| GET | `/admin/permissions` | List all permissions | `roles.view` |
| GET | `/admin/roles/hierarchy` | Get role hierarchy tree | `roles.view` |
| PUT | `/admin/roles/:id/parent` | Set role parent | `roles.update` |
| POST | `/admin/roles/validate-permissions` | Validate permission codes | `roles.view` |
| GET | `/admin/roles/templates` | List role templates | `roles.view` |
| GET | `/admin/roles/templates/:id` | Get role template | `roles.view` |
| POST | `/admin/roles/templates` | Create role template | `roles.create` |
| POST | `/admin/roles/:id/apply-template` | Apply template to role | `roles.update` |
| GET | `/admin/roles/assignment-history` | Get assignment history | `roles.view` |
| GET | `/admin/users/:id/role-history` | Get user role history | `users.view` |
| POST | `/admin/users/:id/roles` | Assign role to user | `users.update` |
| DELETE | `/admin/users/:id/roles/:roleId` | Remove role from user | `users.update` |
| PUT | `/admin/roles/:id/permissions/bulk` | Bulk update permissions | `roles.update` |
| POST | `/admin/users/bulk-assign-roles` | Bulk assign roles | `users.update` |
| POST | `/admin/roles/:id/copy-permissions` | Copy permissions to role | `roles.update` |

### Activity Logs (NEW)

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/activity-logs` | List activity logs with filtering | `activity.view` |
| GET | `/admin/activity-logs/:id` | Get single log entry | `activity.view` |
| GET | `/admin/activity-logs/stats` | Get activity statistics | `activity.view` |
| GET | `/admin/activity-logs/user/:userId` | Get user activity | `activity.view` |
| GET | `/admin/activity-logs/resource/:type/:id` | Get resource activity | `activity.view` |
| GET | `/admin/activity-logs/export` | Export activity logs (CSV/JSON) | `activity.export` |
| GET | `/admin/activity-logs/login-history` | Get login history | `activity.view` |

### Settings

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/settings` | Get all settings | `settings.view` |
| GET | `/admin/settings/:key` | Get setting by key | `settings.view` |
| PUT | `/admin/settings` | Bulk update settings | `settings.update` |
| PUT | `/admin/settings/:key` | Update single setting | `settings.update` |
| POST | `/admin/settings` | Create new setting | `settings.create` |
| DELETE | `/admin/settings/:key` | Delete setting | `settings.delete` |
| GET | `/admin/settings/categories` | Get settings categories | `settings.view` |
| GET | `/settings` | Get public settings | Public |

---

## Catalog Service (`service-catalog`)

### Public Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/products` | List products | Public |
| GET | `/products/:id` | Get product | Public |
| GET | `/products/slug/:slug` | Get by slug | Public |
| GET | `/categories` | List categories | Public |
| GET | `/categories/:id` | Get category | Public |
| GET | `/collections` | List collections | Public |
| GET | `/search` | Search products | Public |

### Admin Products

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/products` | List all products | `products.view` |
| GET | `/admin/products/:id` | Get product by ID | `products.view` |
| POST | `/admin/products` | Create product | `products.create` |
| PUT | `/admin/products/:id` | Update product | `products.update` |
| DELETE | `/admin/products/:id` | Delete product | `products.delete` |
| POST | `/admin/products/:id/variants` | Add variant | `products.variants` |
| POST | `/admin/products/:id/media` | Add media | `products.media` |
| GET | `/admin/products/export` | Export products (CSV/JSON) | `products.export` |
| POST | `/admin/products/import` | Import products | `products.import` |
| PUT | `/admin/products/bulk` | Bulk update products | `products.update` |
| DELETE | `/admin/products/bulk` | Bulk delete products | `products.delete` |
| PATCH | `/admin/products/bulk/publish` | Bulk publish/unpublish | `products.update` |
| POST | `/admin/products/:id/duplicate` | Duplicate product | `products.create` |
| GET | `/admin/products/stats` | Get product statistics | `products.view` |
| GET | `/admin/products/import/template` | Get import template | `products.view` |

### Admin Categories

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/categories` | List categories | `categories.view` |
| POST | `/admin/categories` | Create category | `categories.create` |
| PUT | `/admin/categories/:id` | Update category | `categories.update` |
| DELETE | `/admin/categories/:id` | Delete category | `categories.delete` |

### Discounts (NEW)

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/discounts` | List discounts | `discounts.view` |
| GET | `/admin/discounts/:id` | Get discount by ID | `discounts.view` |
| POST | `/admin/discounts` | Create discount | `discounts.create` |
| PUT | `/admin/discounts/:id` | Update discount | `discounts.update` |
| DELETE | `/admin/discounts/:id` | Delete discount | `discounts.delete` |
| PATCH | `/admin/discounts/:id/activate` | Toggle activation | `discounts.activate` |
| POST | `/admin/discounts/validate` | Validate discount code | `discounts.view` |
| GET | `/admin/discounts/:id/usage` | Get usage statistics | `discounts.view` |

---

## Order Service (`service-order`)

### Public Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/orders` | Create order | Bearer |
| GET | `/orders/:id` | Get order | Bearer |
| GET | `/orders/my` | Get user's orders | Bearer |

### Admin Orders

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/orders` | List orders with filtering | `orders.view` |
| GET | `/admin/orders/:id` | Get order details | `orders.view` |
| PUT | `/admin/orders/:id` | Update order | `orders.update` |
| POST | `/admin/orders/:id/cancel` | Cancel order | `orders.cancel` |
| POST | `/admin/orders/:id/fulfill` | Create fulfillment | `orders.fulfill` |
| POST | `/admin/orders/:id/refund` | Process refund | `orders.refund` |
| GET | `/admin/orders/:id/timeline` | Get order timeline | `orders.view` |
| POST | `/admin/orders/:id/notes` | Add order note | `orders.view` |
| GET | `/admin/orders/:id/notes` | Get order notes | `orders.view` |
| GET | `/admin/orders/:id/print` | Generate print document | `orders.print` |
| GET | `/admin/orders/export` | Export orders | `orders.export` |

---

## Customer Service (`service-customer`)

### Public Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/customers/me` | Get my profile | Bearer |
| PUT | `/customers/me` | Update profile | Bearer |
| GET | `/customers/me/addresses` | Get addresses | Bearer |
| POST | `/customers/me/addresses` | Add address | Bearer |

### Admin Customers

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/customers` | List customers with filtering | `customers.view` |
| GET | `/admin/customers/:id` | Get customer details | `customers.view` |
| POST | `/admin/customers` | Create customer | `customers.create` |
| PUT | `/admin/customers/:id` | Update customer | `customers.update` |
| DELETE | `/admin/customers/:id` | Delete customer | `customers.delete` |
| GET | `/admin/customers/:id/orders` | Get customer orders | `customers.view` |
| POST | `/admin/customers/:id/notes` | Add customer note | `customers.notes` |
| GET | `/admin/customers/:id/notes` | Get customer notes | `customers.view` |
| GET | `/admin/customers/:id/activity` | Get customer activity | `customers.view` |
| GET | `/admin/customers/export` | Export customers | `customers.export` |
| GET | `/admin/customers/stats` | Get customer statistics | `customers.view` |

### Customer Segments

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/segments` | List segments | `customers.segments` |
| POST | `/admin/segments` | Create segment | `customers.segments` |
| PUT | `/admin/segments/:id` | Update segment | `customers.segments` |
| DELETE | `/admin/segments/:id` | Delete segment | `customers.segments` |
| POST | `/admin/customers/:id/segments` | Assign segments | `customers.segments` |

---

## Inventory Service (`service-inventory`)

### Admin Inventory

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/inventory` | List stock items | `inventory.view` |
| GET | `/admin/inventory/:id` | Get stock item | `inventory.view` |
| POST | `/admin/inventory/adjust` | Adjust stock | `inventory.adjust` |
| GET | `/admin/inventory/low-stock` | Get low stock alerts | `inventory.view` |
| GET | `/admin/inventory/movements` | Get stock movements | `inventory.view` |
| GET | `/admin/inventory/alerts` | Get stock alerts | `inventory.view` |
| GET | `/admin/inventory/export` | Export inventory | `inventory.export` |
| GET | `/admin/inventory/stats` | Get inventory statistics | `inventory.view` |

### Warehouses

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/warehouses` | List warehouses | `inventory.view` |
| POST | `/admin/warehouses` | Create warehouse | `inventory.update` |
| GET | `/admin/warehouses/:id/stock` | Get warehouse stock | `inventory.view` |

### Transfers

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| POST | `/admin/transfers` | Create transfer | `inventory.transfer` |
| GET | `/admin/transfers` | List transfers | `inventory.view` |
| PUT | `/admin/transfers/:id/receive` | Receive transfer | `inventory.receive` |

---

## Reporting Service (`service-reporting`)

### Analytics Dashboard

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/analytics/dashboard` | Combined dashboard metrics | `analytics.view` |
| GET | `/admin/analytics/sales` | Sales overview | `analytics.view` |
| GET | `/admin/analytics/products` | Product analytics | `analytics.view` |
| GET | `/admin/analytics/customers` | Customer analytics | `analytics.view` |
| GET | `/admin/analytics/inventory` | Inventory analytics | `analytics.view` |
| GET | `/admin/analytics/export` | Export analytics data | `analytics.export` |

### Reports

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/reports/sales/overview` | Sales overview | `analytics.view` |
| GET | `/reports/sales/trends` | Sales trends | `analytics.view` |
| GET | `/reports/sales/top-products` | Top products | `analytics.view` |
| GET | `/reports/orders/status-breakdown` | Order status | `analytics.view` |
| GET | `/reports/inventory/low-stock` | Low stock | `analytics.view` |
| GET | `/reports/customers/growth` | Customer growth | `analytics.view` |
| GET | `/reports/export/:type` | Export report | `analytics.export` |

---

## Standard Response Formats

### Success Response
```json
{
    "success": true,
    "message": "Operation successful",
    "data": {...}
}
```

### Paginated Response
```json
{
    "success": true,
    "message": "Data retrieved successfully",
    "data": [...],
    "meta": {
        "page": 1,
        "limit": 20,
        "total_count": 150,
        "total_pages": 8
    }
}
```

### Error Response
```json
{
    "success": false,
    "error": {
        "code": "ERROR_CODE",
        "message": "Error message",
        "details": null
    }
}
```

---

## Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Success |
| 201 | Created - Resource created |
| 204 | No Content - Successful deletion |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - No/invalid token |
| 403 | Forbidden - No permission |
| 404 | Not Found - Resource not found |
| 409 | Conflict - Resource already exists |
| 422 | Unprocessable - Validation error |
| 500 | Server Error - Internal error |
| 503 | Service Unavailable |

---

## Query Parameters

### Pagination
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)

### Sorting
- `sort_by` - Field to sort by
- `sort_order` - `asc` or `desc`

### Filtering
- `search` - Search term
- `status` - Filter by status
- `date_from` - Start date (YYYY-MM-DD)
- `date_to` - End date (YYYY-MM-DD)

### Export
- `format` - Export format (`csv`, `json`, `pdf`)
