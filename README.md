# E-commerce Platform

> 🛒 E-commerce platform for Malaysian product products with microservices architecture

---

## 📋 Project Overview

**E-commerce Platform** is a full-featured e-commerce platform built with microservices architecture, designed for selling traditional Malaysian product products online.

### Tech Stack

| Layer | Technology |
|-------|------------|
| **Backend** | Go 1.23, Gin Framework, GORM |
| **Frontend** | Next.js 14, TypeScript, Tailwind CSS |
| **Database** | PostgreSQL 16 |
| **Cache** | Redis 7 |
| **Storage** | MinIO (S3-compatible) |
| **Message Queue** | NATS |
| **Reverse Proxy** | Nginx |
| **Container** | Docker, Docker Compose |

---

## 🏗️ Architecture

```
                    ┌─────────────────────────────────────────────────────┐
                    │                    NGINX (80/443)                   │
                    │              Reverse Proxy + SSL + Rate Limit       │
                    └─────────────────────────────────────────────────────┘
                                             │
         ┌───────────────────────────────────┼───────────────────────────────────┐
         ▼                                   ▼                                   ▼
┌─────────────────┐              ┌─────────────────┐              ┌─────────────────┐
│   Storefront    │              │     Admin       │              │   Warehouse     │
│   (Next.js)     │              │   (Next.js)     │              │   (Next.js)     │
│   Port: 3000    │              │   /admin        │              │   /warehouse    │
└─────────────────┘              └─────────────────┘              └─────────────────┘
         │                                   │                                   │
         └───────────────────────────────────┼───────────────────────────────────┘
                                             ▼
                              ┌────────────────────────┐
                              │      API Gateway       │
                              │    /api/v1/*           │
                              └────────────────────────┘
                                             │
    ┌────────────────┬────────────────┬──────┴──────┬────────────────┬────────────────┐
    ▼                ▼                ▼             ▼                ▼                ▼
┌────────┐    ┌──────────┐    ┌───────────┐   ┌─────────┐    ┌──────────┐    ┌──────────┐
│  Auth  │    │ Catalog  │    │ Inventory │   │  Order  │    │ Customer │    │  Agent   │
│  8001  │    │   8002   │    │   8003    │   │  8005   │    │   8004   │    │   8006   │
└────────┘    └──────────┘    └───────────┘   └─────────┘    └──────────┘    └──────────┘
    │                │                │             │                │                │
    └────────────────┴────────────────┼─────────────┴────────────────┴────────────────┘
                                      ▼
    ┌─────────────────────────────────┴─────────────────────────────────┐
    │                         Infrastructure                            │
    │  ┌──────────┐  ┌───────┐  ┌───────┐  ┌──────┐  ┌──────────────┐  │
    │  │ Postgres │  │ Redis │  │ MinIO │  │ NATS │  │ Notification │  │
    │  │   5432   │  │ 6379  │  │ 9000  │  │ 4222 │  │     8008     │  │
    │  └──────────┘  └───────┘  └───────┘  └──────┘  └──────────────┘  │
    └───────────────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
ecommerceDesaMurniproduct/
│
├── 🔧 infra-platform/          # Infrastructure & deployment
│   ├── docker-compose.vps.yml  # Production Docker Compose
│   ├── nginx/                  # Nginx configuration
│   │   ├── nginx.conf          # Main config
│   │   └── proxy_params        # Proxy settings
│   └── .env                    # Environment variables
│
├── 📚 lib-common/              # Shared Go library
│   ├── auth/                   # JWT authentication
│   ├── database/               # PostgreSQL & Redis helpers
│   ├── middleware/             # CORS, Rate limiting, Recovery
│   ├── logger/                 # Zap structured logging
│   └── response/               # Standard API responses
│
├── 🔐 service-auth/            # Authentication service (8001)
│   ├── cmd/server/             # Entry point
│   ├── internal/
│   │   ├── handlers/           # HTTP handlers
│   │   ├── services/           # Business logic
│   │   ├── repository/         # Data access
│   │   └── models/             # Domain models
│   └── Dockerfile
│
├── 📦 service-catalog/         # Product catalog (8002)
├── 📊 service-inventory/       # Stock management (8003)
├── 🛒 service-order/           # Order processing (8005)
├── 👤 service-customer/        # Customer management (8004)
├── 🤝 service-agent/           # Agent/reseller system (8006)
├── 📈 service-reporting/       # Analytics & reports (8007)
├── 📧 service-notification/    # Email/SMS notifications (8008)
│
├── 🖥️ frontend-storefront/     # Customer-facing store
│   ├── src/app/                # Next.js App Router
│   ├── src/components/         # React components
│   └── Dockerfile
│
├── 👔 frontend-admin/          # Admin dashboard (/admin)
├── 📦 frontend-warehouse/      # Warehouse portal (/warehouse)
├── 📱 frontend-agent/          # Agent components library
│
├── 🗄️ database/                # Database migrations
│   └── migrations/             # SQL migration files
│
└── 📖 ecommerce-docs/             # This documentation
```

---

## 🚀 Services

### Backend Services

| Service | Port | Description |
|---------|------|-------------|
| **service-auth** | 8001 | Authentication, JWT, RBAC | 
| **service-catalog** | 8002 | Products, Categories, Images |
| **service-inventory** | 8003 | Stock levels, Warehouses, Transfers |DONE
| **service-order** | 8005 | Orders, Payments, Shipping |
| **service-customer** | 8004 | Customer profiles, Wishlist |
| **service-agent** | 8006 | Agents, Commissions |
| **service-reporting** | 8007 | Sales reports, Analytics |
| **service-notification** | 8008 | Email, SMS notifications |

### Frontend Applications

| Application | Path | Description |
|-------------|------|-------------|
| **frontend-storefront** | `/` | Public e-commerce store |
| **frontend-admin** | `/admin` | Admin management dashboard |
| **frontend-warehouse** | `/warehouse` | Warehouse operations (PWA) |

### Infrastructure

| Service | Port | Description |
|---------|------|-------------|
| **Nginx** | 80, 443 | Reverse proxy, SSL, Rate limiting |
| **PostgreSQL** | 5432 | Primary database |
| **Redis** | 6379 | Cache & sessions |
| **MinIO** | 9000 | Object storage (images) |
| **NATS** | 4222 | Message queue |

---

## 🛠️ Quick Start

### Prerequisites

- Docker & Docker Compose
- Git
- Node.js 20+ (for local development)
- Go 1.23+ (for local development)

### Clone Repositories

```bash
# Clone all repositories
gh repo list ecommerceDesaMurniproduct --json name -q ".[].name" | \
  xargs -I {} git clone https://github.com/ecommerceDesaMurniproduct/{}.git
```

### Deploy to VPS

```bash
cd infra-platform

# Create .env file
cp .env.example .env
# Edit .env with your values

# Start all services
docker compose -f docker-compose.vps.yml up -d --build

# View logs
docker compose -f docker-compose.vps.yml logs -f

# Check status
docker compose -f docker-compose.vps.yml ps
```

---

## 🔑 Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `DOMAIN` | VPS IP or domain | `72.62.67.167` |
| `POSTGRES_USER` | Database user | `ecommerce` |
| `POSTGRES_PASSWORD` | Database password | `secure_password` |
| `JWT_SECRET` | JWT signing key (32+ chars) | `your_secret_key` |
| `MINIO_ROOT_USER` | MinIO admin user | `ecommerceadmin` |
| `MINIO_ROOT_PASSWORD` | MinIO admin password | `secure_password` |
| `CORS_ORIGINS` | Allowed origins | `http://domain.com` |
| `SMTP_USER` | Email username | `email@gmail.com` |
| `SMTP_PASSWORD` | Email app password | `app_password` |

---

## 🔒 Security Features

- ✅ JWT authentication with 15-minute expiry
- ✅ bcrypt password hashing
- ✅ Rate limiting (10 req/s API, 5 req/m login)
- ✅ Non-root Docker containers
- ✅ Internal services bound to 127.0.0.1
- ✅ Security headers (X-Frame-Options, CSP, etc.)
- ✅ HTTPS ready (SSL configuration included)

---

## 📊 Resource Requirements

**Minimum VPS Specs:** 4GB RAM, 2 vCPU

| Category | Allocated | 
|----------|-----------|
| Total Memory | ~3.4 GB |
| Total CPU | ~3.25 vCPU |

---

## 📝 API Documentation

### Base URL
```
http://your-domain.com/api/v1
```

### Authentication
```http
POST /api/v1/auth/login
POST /api/v1/auth/register
POST /api/v1/auth/refresh
GET  /api/v1/auth/me
```

### Products
```http
GET  /api/v1/products
GET  /api/v1/products/:id
POST /api/v1/products (admin)
PUT  /api/v1/products/:id (admin)
```

### Orders
```http
POST /api/v1/orders
GET  /api/v1/orders
GET  /api/v1/orders/:id
PUT  /api/v1/orders/:id/status (admin)
```

---

## 📞 Support

For issues and questions, please create an issue in the relevant repository.

---

## 📜 License

MIT License - E-commerce Platform © 2024
