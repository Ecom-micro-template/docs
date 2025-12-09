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

### Admin Endpoints

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/products` | List all products | `products.view` |
| POST | `/admin/products` | Create product | `products.create` |
| PUT | `/admin/products/:id` | Update product | `products.update` |
| DELETE | `/admin/products/:id` | Delete product | `products.delete` |
| POST | `/admin/products/:id/variants` | Add variant | `products.variants` |
| POST | `/admin/products/:id/media` | Add media | `products.media` |
| GET | `/admin/categories` | List categories | `categories.view` |
| POST | `/admin/categories` | Create category | `categories.create` |
| PUT | `/admin/categories/:id` | Update category | `categories.update` |
| DELETE | `/admin/categories/:id` | Delete category | `categories.delete` |

---

## Order Service (`service-order`)

### Public Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/orders` | Create order | Bearer |
| GET | `/orders/:id` | Get order | Bearer |
| GET | `/orders/my` | Get user's orders | Bearer |

### Admin Endpoints

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/orders` | List orders | `orders.view` |
| GET | `/admin/orders/:id` | Get order | `orders.view` |
| PUT | `/admin/orders/:id` | Update order | `orders.update` |
| POST | `/admin/orders/:id/cancel` | Cancel order | `orders.cancel` |
| POST | `/admin/orders/:id/fulfill` | Create fulfillment | `orders.fulfill` |
| POST | `/admin/orders/:id/refund` | Process refund | `orders.refund` |
| GET | `/admin/orders/:id/timeline` | Get timeline | `orders.view` |
| POST | `/admin/orders/:id/notes` | Add note | `orders.view` |

---

## Customer Service (`service-customer`)

### Public Endpoints

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/customers/me` | Get my profile | Bearer |
| PUT | `/customers/me` | Update profile | Bearer |
| GET | `/customers/me/addresses` | Get addresses | Bearer |
| POST | `/customers/me/addresses` | Add address | Bearer |

### Admin Endpoints

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/customers` | List customers | `customers.view` |
| GET | `/admin/customers/:id` | Get customer | `customers.view` |
| POST | `/admin/customers` | Create customer | `customers.create` |
| PUT | `/admin/customers/:id` | Update customer | `customers.update` |
| DELETE | `/admin/customers/:id` | Delete customer | `customers.delete` |
| GET | `/admin/customers/:id/orders` | Get orders | `customers.view` |
| POST | `/admin/customers/:id/notes` | Add note | `customers.notes` |
| GET | `/admin/segments` | List segments | `customers.segments` |

---

## Inventory Service (`service-inventory`)

### Admin Endpoints

| Method | Endpoint | Description | Permission |
|--------|----------|-------------|------------|
| GET | `/admin/inventory` | List stock | `inventory.view` |
| GET | `/admin/inventory/:id` | Get stock item | `inventory.view` |
| POST | `/admin/inventory/adjust` | Adjust stock | `inventory.adjust` |
| GET | `/admin/warehouses` | List warehouses | `inventory.view` |
| POST | `/admin/warehouses` | Create warehouse | `inventory.update` |
| POST | `/admin/transfers` | Create transfer | `inventory.transfer` |
| GET | `/admin/transfers` | List transfers | `inventory.view` |
| PUT | `/admin/transfers/:id/receive` | Receive transfer | `inventory.receive` |
| GET | `/admin/movements` | Stock movements | `inventory.view` |

---

## Reporting Service (`service-reporting`)

### Admin Endpoints

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
    "data": {...},
    "message": "Operation successful"
}
```

### Paginated Response
```json
{
    "success": true,
    "data": [...],
    "pagination": {
        "page": 1,
        "limit": 20,
        "total": 150,
        "total_pages": 8
    }
}
```

### Error Response
```json
{
    "success": false,
    "error": "Error message",
    "code": "ERROR_CODE"
}
```

---

## Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | OK - Success |
| 201 | Created - Resource created |
| 400 | Bad Request - Invalid input |
| 401 | Unauthorized - No/invalid token |
| 403 | Forbidden - No permission |
| 404 | Not Found - Resource not found |
| 422 | Unprocessable - Validation error |
| 500 | Server Error - Internal error |
