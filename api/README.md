# Niaga Platform API Documentation

> **RESTful API Reference** - Complete guide to the Niaga Platform HTTP APIs

## Table of Contents

- [Overview](#overview)
- [Authentication](#authentication)
- [Base URLs](#base-urls)
- [Common Patterns](#common-patterns)
- [Quick Reference](#quick-reference)
- [Service APIs](#service-apis)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Webhooks](#webhooks)
- [Code Examples](#code-examples)

## Overview

The Niaga Platform provides RESTful HTTP APIs for all platform functionality. All APIs follow consistent patterns for authentication, pagination, error handling, and response formats.

### API Specifications

- **Format**: OpenAPI 3.0 (Swagger)
- **Specification File**: [openapi.yaml](openapi.yaml)
- **Interactive Documentation**: Swagger UI (see [Viewing API Docs](#viewing-api-docs))

### Key Features

- **RESTful** design principles
- **JSON** request/response payloads
- **JWT** authentication
- **Pagination** for list endpoints
- **Versioning** via URL (`/api/v1/`)
- **Standard** HTTP status codes

## Authentication

### JWT (JSON Web Tokens)

Most API endpoints require authentication using JWT access tokens.

#### 1. Obtain Access Token

**Login Endpoint**:

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response**:

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "dGhpc2lzYXJlZnJl...",
  "expires_in": 900,
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "role": "customer"
  }
}
```

#### 2. Use Access Token

Include the token in the `Authorization` header:

```http
GET /api/v1/order
Authorization: Bearer eyJhbGciOiJIUzI1NiIs...
```

#### 3. Refresh Token

When access token expires, use refresh token to get a new one:

```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "dGhpc2lzYXJlZnJl..."
}
```

### Token Expiration

- **Access Token**: 15 minutes
- **Refresh Token**: 7 days

### Public Endpoints

The following endpoints do NOT require authentication:

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `GET /api/v1/catalog/*` (all catalog endpoints)
- `GET /api/v1/search`
- `/health` (all services)

## Base URLs

### Development

```
http://localhost:8080/api/v1
```

Individual service ports (for direct access):

- Auth: `http://localhost:8001`
- Catalog: `http://localhost:8002`
- Inventory: `http://localhost:8003`
- Order: `http://localhost:8004`
- Customer: `http://localhost:8005`
- Notification: `http://localhost:8006`
- Agent: `http://localhost:8007`
- Reporting: `http://localhost:8008`

### Production

```
https://api.niaga.com/api/v1
```

All requests go through the API Gateway (Traefik).

## Common Patterns

### Pagination

List endpoints support pagination:

**Request**:

```http
GET /api/v1/catalog/products?page=2&limit=20
```

**Response**:

```json
{
  "products": [...],
  "pagination": {
    "page": 2,
    "limit": 20,
    "total": 150,
    "pages": 8
  }
}
```

**Query Parameters**:

- `page` - Page number (default: 1)
- `limit` - Items per page (default: 20, max: 100)

### Filtering

Filter results using query parameters:

```http
GET /api/v1/catalog/products?category=electronics&min_price=100&max_price=500
```

### Sorting

Sort results using `sort` and `order` parameters:

```http
GET /api/v1/catalog/products?sort=base_price&order=asc
```

Common sort fields:

- `created_at` - Creation date
- `updated_at` - Last modified date
- `name` - Alphabetical
- `base_price` - Price

### Timestamps

All timestamps are in **ISO 8601 UTC format**:

```json
{
  "created_at": "2025-12-02T01:30:00Z",
  "updated_at": "2025-12-02T10:00:00Z"
}
```

### UUIDs

All entity IDs use **UUID v4** format:

```json
{
  "id": "a3bb189e-8bf9-3888-9912-ace4e6543002"
}
```

## Quick Reference

### Authentication Service (Port 8001)

| Endpoint                       | Method | Auth | Description            |
| ------------------------------ | ------ | ---- | ---------------------- |
| `/api/v1/auth/register`        | POST   | No   | Register new user      |
| `/api/v1/auth/login`           | POST   | No   | User login             |
| `/api/v1/auth/logout`          | POST   | Yes  | User logout            |
| `/api/v1/auth/refresh`         | POST   | No   | Refresh access token   |
| `/api/v1/auth/me`              | GET    | Yes  | Get current user       |
| `/api/v1/auth/change-password` | POST   | Yes  | Change password        |
| `/api/v1/auth/forgot-password` | POST   | No   | Request password reset |
| `/api/v1/auth/reset-password`  | POST   | No   | Reset password         |

### Catalog Service (Port 8002)

#### Categories

| Endpoint                                    | Method | Auth  | Description              |
| ------------------------------------------- | ------ | ----- | ------------------------ |
| `/api/v1/catalog/categories`                | GET    | No    | List all categories      |
| `/api/v1/catalog/categories/:slug`          | GET    | No    | Get category by slug     |
| `/api/v1/catalog/categories/:slug/products` | GET    | No    | Get products in category |
| `/api/v1/catalog/admin/categories`          | POST   | Admin | Create category          |
| `/api/v1/catalog/admin/categories/:id`      | PUT    | Admin | Update category          |
| `/api/v1/catalog/admin/categories/:id`      | DELETE | Admin | Delete category          |

#### Products

| Endpoint                                  | Method | Auth  | Description          |
| ----------------------------------------- | ------ | ----- | -------------------- |
| `/api/v1/catalog/products`                | GET    | No    | List products        |
| `/api/v1/catalog/products/:slug`          | GET    | No    | Get product details  |
| `/api/v1/catalog/products/:slug/variants` | GET    | No    | Get product variants |
| `/api/v1/catalog/products/:slug/related`  | GET    | No    | Get related products |
| `/api/v1/catalog/admin/products`          | POST   | Admin | Create product       |
| `/api/v1/catalog/admin/products/:id`      | PUT    | Admin | Update product       |
| `/api/v1/catalog/admin/products/:id`      | DELETE | Admin | Delete product       |

#### Product Images

| Endpoint                                                      | Method | Auth  | Description       |
| ------------------------------------------------------------- | ------ | ----- | ----------------- |
| `/api/v1/catalog/admin/products/:id/images`                   | POST   | Admin | Upload image      |
| `/api/v1/catalog/admin/products/:id/images/:image_id`         | DELETE | Admin | Delete image      |
| `/api/v1/catalog/admin/products/:id/images/:image_id/primary` | PUT    | Admin | Set primary image |

#### Product Variants

| Endpoint                                                  | Method | Auth  | Description    |
| --------------------------------------------------------- | ------ | ----- | -------------- |
| `/api/v1/catalog/admin/products/:id/variants`             | POST   | Admin | Create variant |
| `/api/v1/catalog/admin/products/:id/variants/:variant_id` | PUT    | Admin | Update variant |
| `/api/v1/catalog/admin/products/:id/variants/:variant_id` | DELETE | Admin | Delete variant |

#### Search

| Endpoint                     | Method | Auth | Description                  |
| ---------------------------- | ------ | ---- | ---------------------------- |
| `/api/v1/search`             | GET    | No   | Search products              |
| `/api/v1/search/suggestions` | GET    | No   | Get autocomplete suggestions |

### Inventory Service (Port 8003)

| Endpoint                             | Method | Auth      | Description           |
| ------------------------------------ | ------ | --------- | --------------------- |
| `/api/v1/inventory/stock`            | GET    | No        | Check stock levels    |
| `/api/v1/inventory/stock/:productId` | GET    | No        | Get product stock     |
| `/api/v1/inventory/warehouses`       | GET    | Warehouse | List warehouses       |
| `/api/v1/inventory/warehouses`       | POST   | Admin     | Create warehouse      |
| `/api/v1/inventory/warehouses/:id`   | GET    | Warehouse | Get warehouse         |
| `/api/v1/inventory/warehouses/:id`   | PUT    | Admin     | Update warehouse      |
| `/api/v1/inventory/movements`        | GET    | Warehouse | List movements        |
| `/api/v1/inventory/movements`        | POST   | Warehouse | Create movement       |
| `/api/v1/inventory/transfer`         | POST   | Warehouse | Create stock transfer |

### Order Service (Port 8004)

#### Cart

| Endpoint                     | Method | Auth     | Description      |
| ---------------------------- | ------ | -------- | ---------------- |
| `/api/v1/cart`               | GET    | Customer | Get cart         |
| `/api/v1/cart/items`         | POST   | Customer | Add to cart      |
| `/api/v1/cart/items/:itemId` | PUT    | Customer | Update cart item |
| `/api/v1/cart/items/:itemId` | DELETE | Customer | Remove from cart |
| `/api/v1/cart`               | DELETE | Customer | Clear cart       |
| `/api/v1/cart/coupon`        | POST   | Customer | Apply coupon     |
| `/api/v1/cart/coupon`        | DELETE | Customer | Remove coupon    |

#### Orders

| Endpoint                     | Method | Auth     | Description       |
| ---------------------------- | ------ | -------- | ----------------- |
| `/api/v1/order`              | GET    | Customer | List user orders  |
| `/api/v1/order`              | POST   | Customer | Create order      |
| `/api/v1/order/:id`          | GET    | Customer | Get order details |
| `/api/v1/order/:id/tracking` | GET    | Customer | Get tracking info |
| `/api/v1/order/:id/cancel`   | POST   | Customer | Cancel order      |

#### Shipping

| Endpoint                   | Method | Auth | Description          |
| -------------------------- | ------ | ---- | -------------------- |
| `/api/v1/shipping/methods` | GET    | No   | Get shipping methods |

### Customer Service (Port 8005)

| Endpoint                                 | Method | Auth     | Description          |
| ---------------------------------------- | ------ | -------- | -------------------- |
| `/api/v1/customer/profile`               | GET    | Customer | Get profile          |
| `/api/v1/customer/profile`               | PUT    | Customer | Update profile       |
| `/api/v1/customer/addresses`             | GET    | Customer | List addresses       |
| `/api/v1/customer/addresses`             | POST   | Customer | Add address          |
| `/api/v1/customer/addresses/:id`         | PUT    | Customer | Update address       |
| `/api/v1/customer/addresses/:id`         | DELETE | Customer | Delete address       |
| `/api/v1/customer/addresses/:id/default` | PUT    | Customer | Set default address  |
| `/api/v1/customer/wishlist`              | GET    | Customer | Get wishlist         |
| `/api/v1/customer/wishlist`              | POST   | Customer | Add to wishlist      |
| `/api/v1/customer/wishlist/:productId`   | DELETE | Customer | Remove from wishlist |

## Error Handling

### HTTP Status Codes

The API uses standard HTTP status codes:

| Code | Meaning               | Description                               |
| ---- | --------------------- | ----------------------------------------- |
| 200  | OK                    | Request succeeded                         |
| 201  | Created               | Resource created successfully             |
| 204  | No Content            | Request succeeded, no response body       |
| 400  | Bad Request           | Invalid request parameters                |
| 401  | Unauthorized          | Missing or invalid authentication         |
| 403  | Forbidden             | Insufficient permissions                  |
| 404  | Not Found             | Resource not found                        |
| 409  | Conflict              | Resource conflict (e.g., duplicate email) |
| 422  | Unprocessable Entity  | Validation error                          |
| 429  | Too Many Requests     | Rate limit exceeded                       |
| 500  | Internal Server Error | Server error                              |
| 503  | Service Unavailable   | Service temporarily unavailable           |

### Error Response Format

All errors return a consistent JSON structure:

```json
{
  "error": "Human-readable error message",
  "code": "ERROR_CODE",
  "details": {
    "field": "Additional context"
  }
}
```

### Common Error Codes

| Code                   | Description                  |
| ---------------------- | ---------------------------- |
| `INVALID_CREDENTIALS`  | Email or password incorrect  |
| `EMAIL_ALREADY_EXISTS` | Email already registered     |
| `PRODUCT_NOT_FOUND`    | Product does not exist       |
| `OUT_OF_STOCK`         | Product out of stock         |
| `INVALID_TOKEN`        | JWT token invalid or expired |
| `INSUFFICIENT_STOCK`   | Not enough stock for order   |
| `VALIDATION_ERROR`     | Request validation failed    |

### Example Error Responses

**Validation Error (422)**:

```json
{
  "error": "Validation failed",
  "code": "VALIDATION_ERROR",
  "details": {
    "email": "Invalid email format",
    "password": "Password must be at least 8 characters"
  }
}
```

**Unauthorized (401)**:

```json
{
  "error": "Invalid or expired token",
  "code": "INVALID_TOKEN"
}
```

**Not Found (404)**:

```json
{
  "error": "Product not found",
  "code": "PRODUCT_NOT_FOUND"
}
```

## Rate Limiting

### Limits

- **Public endpoints**: 100 requests/minute per IP
- **Authenticated endpoints**: 1000 requests/minute per user
- **Admin endpoints**: 5000 requests/minute per user

### Rate Limit Headers

Responses include rate limit information:

```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1638360000
```

### Rate Limit Exceeded

When rate limit is exceeded, API returns `429 Too Many Requests`:

```json
{
  "error": "Rate limit exceeded",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 45
}
```

## Webhooks

### Available Webhooks

Niaga Platform can send webhooks for the following events:

- `order.created` - New order placed
- `order.updated` - Order status changed
- `payment.completed` - Payment successful
- `payment.failed` - Payment failed
- `product.created` - New product added
- `product.updated` - Product information updated

### Webhook Payload

```json
{
  "event": "order.created",
  "timestamp": "2025-12-02T10:00:00Z",
  "data": {
    "order_id": "uuid",
    "order_number": "ORD-20251202-000001",
    ...
  }
}
```

### Webhook Security

Webhooks include `X-Niaga-Signature` header for verification:

```http
X-Niaga-Signature: sha256=a3f5b8c...
```

Verify using HMAC-SHA256 with your webhook secret.

## Code Examples

### JavaScript/TypeScript

```typescript
// Login
const login = async (email: string, password: string) => {
  const response = await fetch("http://localhost:8080/api/v1/auth/login", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ email, password }),
  });

  if (!response.ok) {
    throw new Error("Login failed");
  }

  const data = await response.json();
  return data.access_token;
};

// Get products
const getProducts = async (page = 1, limit = 20) => {
  const response = await fetch(
    `http://localhost:8080/api/v1/catalog/products?page=${page}&limit=${limit}`
  );

  const data = await response.json();
  return data.products;
};

// Create order (authenticated)
const createOrder = async (token: string, orderData: any) => {
  const response = await fetch("http://localhost:8080/api/v1/order", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(orderData),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error);
  }

  return await response.json();
};
```

### Python

```python
import requests

BASE_URL = "http://localhost:8080/api/v1"

# Login
def login(email, password):
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": password}
    )
    response.raise_for_status()
    return response.json()["access_token"]

# Get products
def get_products(page=1, limit=20):
    response = requests.get(
        f"{BASE_URL}/catalog/products",
        params={"page": page, "limit": limit}
    )
    response.raise_for_status()
    return response.json()["products"]

# Create order (authenticated)
def create_order(token, order_data):
    response = requests.post(
        f"{BASE_URL}/order",
        json=order_data,
        headers={"Authorization": f"Bearer {token}"}
    )
    response.raise_for_status()
    return response.json()
```

### cURL

```bash
# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Get products
curl http://localhost:8080/api/v1/catalog/products?page=1&limit=20

# Search products
curl "http://localhost:8080/api/v1/search?q=headphones&min_price=100"

# Add to cart (authenticated)
curl -X POST http://localhost:8080/api/v1/cart/items \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"product_id":"uuid","quantity":2}'

# Create order (authenticated)
curl -X POST http://localhost:8080/api/v1/order \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d @order.json
```

## Viewing API Docs

### Swagger UI

Run Swagger UI to view interactive API documentation:

```bash
docker run -p 8090:8080 \
  -e SWAGGER_JSON=/docs/openapi.yaml \
  -v $(pwd)/docs/api:/docs \
  swaggerapi/swagger-ui
```

Open http://localhost:8090 to view and test APIs.

### Redoc

Alternative documentation viewer:

```bash
docker run -p 8090:80 \
  -e SPEC_URL=/docs/openapi.yaml \
  -v $(pwd)/docs/api:/usr/share/nginx/html/docs \
  redocly/redoc
```

## Best Practices

### 1. Use HTTPS in Production

Always use HTTPS for API requests in production to encrypt sensitive data.

### 2. Handle Token Expiration

Implement automatic token refresh when access token expires.

### 3. Implement Retry Logic

Retry failed requests with exponential backoff:

- First retry: 1 second
- Second retry: 2 seconds
- Third retry: 4 seconds
- Maximum: 3 retries

### 4. Cache Responses

Cache GET responses where appropriate (products, categories) to reduce API calls.

### 5. Validate Input

Always validate user input before sending to API.

### 6. Handle Errors Gracefully

Display user-friendly error messages based on API error responses.

## Versioning

The API is versioned via URL path:

- Current version: `/api/v1/`
- Future versions: `/api/v2/`, `/api/v3/`, etc.

We maintain backward compatibility within major versions. When breaking changes are needed, we release a new major version.

## Support

For API support:

- **Documentation**: This guide and OpenAPI spec
- **Issues**: [GitHub Issues](https://github.com/niaga-platform/issues)
- **Email**: api-support@niaga.com

## Related Documentation

- [OpenAPI Specification](openapi.yaml) - Complete API spec
- [Architecture](../ARCHITECTURE.md) - System architecture
- [Database Schema](../DATABASE-SCHEMA.md) - Database design
- [Authentication Guide](../services/auth/README.md) - Auth service details

---

**Last Updated**: 2025-12-02  
**API Version**: 1.0.0
