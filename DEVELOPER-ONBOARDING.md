# Developer Onboarding Guide

> **Welcome to Niaga Platform** - Complete guide for new developers

## Table of Contents

- [Welcome](#welcome)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Understanding the Codebase](#understanding-the-codebase)
- [Development Workflow](#development-workflow)
- [Code Standards](#code-standards)
- [Testing](#testing)
- [Common Tasks](#common-tasks)
- [Resources](#resources)

## Welcome

Welcome to the Niaga Platform team! This guide will help you get up to speed with our e-commerce platform built on microservices architecture.

### What is Niaga Platform?

Niaga is an **enterprise e-commerce platform** with:

- **8 Backend Microservices** (Go)
- **4 Frontend Applications** (Next.js 14)
- **Event-Driven Architecture** (NATS)
- **Multi-Warehouse Inventory**
- **Agent Management System**

### Your First Week Goals

**Day 1-2**: Environment setup, run platform locally  
**Day 3-4**: Explore architecture, understand services  
**Day 5**: Make your first contribution (docs or small bugfix)

## Prerequisites

### Required Skills

- **Backend**: Go (basic to intermediate)
- **Frontend**: React/Next.js, TypeScript
- **Database**: PostgreSQL, SQL basics
- **DevOps**: Docker, Docker Compose
- **Version Control**: Git

### Tools to Install

#### 1. Core Development Tools

```bash
# Git
https://git-scm.com/downloads

# Docker Desktop (includes Docker Compose)
https://www.docker.com/products/docker-desktop

# Go 1.22+
https://golang.org/dl/

# Node.js 18+ and pnpm
https://nodejs.org/
npm install -g pnpm

# Code Editor (VS Code recommended)
https://code.visualstudio.com/
```

#### 2. VS Code Extensions (Recommended)

- **Go** by Go Team at Google
- **ES Lint** by Microsoft
- **Prettier** by Prettier
- **Docker** by Microsoft
- **Thunder Client** (API testing)
- **GitLens** by GitKraken

#### 3. Optional but Useful

```bash
# Database GUI
https://www.pgadmin.org/                    # pgAdmin
https://tableplus.com/                       # TablePlus
https://dbeaver.io/                          # DBeaver

# API Testing
https://www.postman.com/                     # Postman
https://insomnia.rest/                       # Insomnia

# Redis GUI
https://github.com/qishibo/AnotherRedisDesktopManager
```

## Getting Started

### 1. Clone the Repository

```bash
# Clone main repository
git clone https://github.com/MuhammadLuqman-99/niaga-platform.git
cd niaga-platform
```

### 2. Environment Setup

```bash
# Copy environment files for all services
for service in service-*; do
  cp $service/.env.example $service/.env
done

# Copy frontend environment files
for app in frontend-*; do
  cp $app/.env.example $app/.env.local
done
```

The default values in `.env.example` should work for local development.

### 3. Start the Platform

```bash
# Start infrastructure services first
docker-compose -f docker-compose.dev.yml up -d postgres redis meilisearch minio nats

# Wait 30 seconds for services to be healthy
docker-compose -f docker-compose.dev.yml ps

# Start backend services
docker-compose -f docker-compose.dev.yml up -d service-auth service-catalog service-inventory service-order service-customer service-notification service-agent service-reporting

# Start frontend applications
docker-compose -f docker-compose.dev.yml up -d frontend-storefront frontend-admin frontend-warehouse frontend-agent

# Start API gateway
docker-compose -f docker-compose.dev.yml up -d traefik
```

**Or start everything at once**:

```bash
docker-compose -f docker-compose.dev.yml up -d
```

### 4. Verify Installation

```bash
# Check all services are running
docker-compose -f docker-compose.dev.yml ps

# Test API endpoints
curl http://localhost:8080/api/v1/catalog/products
curl http://localhost:8002/health  # Catalog service directly

# Access applications
# Storefront: http://localhost:3000
# Admin Panel: http://localhost:3001
# Traefik Dashboard: http://localhost:8081
```

### 5. Initialize Data (Optional)

```bash
# The database is automatically initialized with schemas

# To seed sample data (TODO: create seed script)
# docker exec -i niaga-postgres psql -U niaga -d niaga < infra-database/seeds/sample-data.sql
```

## Understanding the Codebase

### Project Structure

```
niaga-platform/
├── service-*/          # 8 Backend microservices (Go)
├── frontend-*/         # 4 Frontend applications (Next.js)
├── infra-platform/     # Infrastructure & DevOps
├── infra-database/     # Database migrations & seeds
├── lib-common/         # Shared Go libraries
├── docs/               # Documentation
└── docker-compose.dev.yml
```

### Service Responsibilities

| Service                  | Port | Description                   |
| ------------------------ | ---- | ----------------------------- |
| **service-auth**         | 8001 | Authentication, JWT, sessions |
| **service-catalog**      | 8002 | Products, categories, search  |
| **service-inventory**    | 8003 | Stock, warehouses, transfers  |
| **service-order**        | 8004 | Orders, cart, checkout        |
| **service-customer**     | 8005 | Customer profiles, addresses  |
| **service-notification** | 8006 | Email, SMS notifications      |
| **service-agent**        | 8007 | Sales agents, commissions     |
| **service-reporting**    | 8008 | Analytics, reports            |

### Backend Service Structure (Go)

```
service-catalog/
├── cmd/
│   └── server/
│       └── main.go               # Entry point
├── internal/
│   ├── config/                   # Configuration
│   ├── models/                   # Database models (GORM)
│   ├── repository/               # Data access layer
│   ├── handlers/                 # HTTP handlers (controllers)
│   ├── services/                 # Business logic
│   └── middleware/               # HTTP middleware
├── migrations/                   # Database migrations
├── .env.example
├── Dockerfile
├── go.mod
└── README.md
```

**Key Patterns**:

- **Handler** → **Service** → **Repository** → **Database**
- Handlers handle HTTP, validate input
- Services contain business logic
- Repositories abstract database access
- Models define data structures

### Frontend Structure (Next.js 14)

```
frontend-storefront/
├── app/                          # App Router (Next.js 14)
│   ├── (shop)/                   # Route group
│   │   ├── page.tsx              # Homepage
│   │   ├── products/             # Product pages
│   │   └── cart/                 # Cart page
│   └── layout.tsx                # Root layout
├── components/
│   ├── layout/                   # Header, Footer, Nav
│   ├── product/                  # Product components
│   ├── cart/                     # Cart components
│   └── ui/                       # shadcn/ui components
├── lib/
│   ├── api/                      # API client functions
│   ├── hooks/                    # Custom React hooks
│   ├── stores/                   # Zustand stores
│   └── utils/                    # Utility functions
└── public/
```

### Data Flow Example

**Creating a Product**:

1. **Admin Panel** → POST `/api/v1/catalog/admin/products`
2. **Traefik Gateway** → Routes to `service-catalog:8002`
3. **Handler** (`product_handler.go`) → Validates request
4. **Service** (business logic) → Generates slug, SKU
5. **Repository** → Saves to PostgreSQL
6. **NATS Event** → Publishes `product.created`
7. **Search Service** → Listens, indexes in Meilisearch
8. **Response** → Returns product JSON

## Development Workflow

### Git Workflow

We use **Git Flow** branching model:

- `main` - Production-ready code
- `develop` - Integration branch
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Emergency production fixes

**Creating a Feature**:

```bash
# Start from develop
git checkout develop
git pull origin develop

# Create feature branch
git checkout -b feature/add-product-reviews

# Make changes, commit often
git add .
git commit -m "feat: add product reviews model"

# Push and create PR
git push origin feature/add-product-reviews
# Create Pull Request on GitHub to develop
```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation
- `style:` Code style (formatting)
- `refactor:` Code restructuring
- `test:` Add/update tests
- `chore:` Maintenance tasks

**Examples**:

```
feat(catalog): add product variant management

fix(auth): resolve JWT expiry issue

docs: update API documentation for orders endpoint

refactor(inventory): optimize stock query performance
```

### Local Development

#### Running a Single Service Locally (Go)

```bash
cd service-catalog

# Install dependencies
go mod download

# Run service
go run cmd/server/main.go

# Or with hot reload (install air first: go install github.com/cosmtrek/air@latest)
air
```

#### Running Frontend Locally

```bash
cd frontend-storefront

# Install dependencies
pnpm install

# Run dev server
pnpm dev

# Open http://localhost:3000
```

#### Making Changes

1. **Create a branch** for your feature/fix
2. **Make changes** to code
3. **Test locally** - run affected services
4. **Write tests** if adding new features
5. **Commit** with conventional commit message
6. **Push** and create Pull Request

### Code Review Process

1. **Create PR** with clear description
2. \*\*Link related issues / tasks
3. **Reviewers assigned** (usually 1-2 people)
4. **CI runs** - tests, linting
5. **Address feedback** - make requested changes
6. **Approved** → Merge to develop
7. **Deploy to staging** - automatic
8. **QA testing** on staging
9. **Merge to main** → Production deployment

## Code Standards

### Go Code Style

Follow [Effective Go](https://golang.org/doc/effective_go):

- Use `gofmt` for formatting
- Run `go vet` for static analysis
- Use `golangci-lint` for comprehensive linting

**Example**:

```go
// Good
func (h *ProductHandler) Create(c *gin.Context) {
    var req CreateProductRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    product, err := h.service.Create(req)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, product)
}
```

### TypeScript/React Code Style

- Use **TypeScript** for type safety
- Follow [Airbnb Style Guide](https://github.com/airbnb/javascript)
- Use **ESLint** and **Prettier**

**Example**:

```typescript
// Good
interface ProductCardProps {
  product: Product;
  onAddToCart: (productId: string) => void;
}

export function ProductCard({ product, onAddToCart }: ProductCardProps) {
  const handleClick = () => {
    onAddToCart(product.id);
  };

  return (
    <div className="product-card">
      <h3>{product.name}</h3>
      <p>${product.base_price}</p>
      <button onClick={handleClick}>Add to Cart</button>
    </div>
  );
}
```

### Database Conventions

- Use **UUIDs** for primary keys
- Use **snake_case** for column names
- Add **indexes** on frequently queried columns
- Use **timestamps** (`created_at`, `updated_at`)
- Use **soft deletes** (`deleted_at`)

### API Conventions

- RESTful endpoints
- Consistent error responses
- Pagination for lists
- API versioning (`/api/v1/`)

## Testing

### Backend Testing (Go)

```bash
cd service-catalog

# Run all tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run specific test
go test -v ./internal/handlers -run TestProductHandler_Create
```

**Example Test**:

```go
func TestProductRepository_Create(t *testing.T) {
    db := setupTestDB(t)
    repo := NewProductRepository(db)

    product := &models.Product{
        Name:      "Test Product",
        BasePrice: 99.99,
    }

    err := repo.Create(product)
    assert.NoError(t, err)
    assert.NotEqual(t, uuid.Nil, product.ID)
}
```

### Frontend Testing

```bash
cd frontend-storefront

# Run tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Generate coverage
pnpm test:coverage
```

## Common Tasks

### Adding a New API Endpoint

1. **Define route** in `main.go`:

```go
catalog.GET("/products/:slug/reviews", reviewHandler.List)
```

2. **Create handler**:

```go
func (h *ReviewHandler) List(c *gin.Context) {
    // Implementation
}
```

3. **Create service** (business logic)
4. **Create repository** (database access)
5. **Add tests**
6. **Update API documentation**

### Adding a Database Table

1. **Create model** in `internal/models/`:

```go
type Review struct {
    ID        uuid.UUID `gorm:"type:uuid;primary_key"`
    ProductID uuid.UUID `gorm:"type:uuid;not null"`
    // ...
}
```

2. **Add to AutoMigrate** in `main.go`:

```go
db.AutoMigrate(&models.Review{})
```

3. **Run service** - migration happens automatically

### Adding a Frontend Page

1. **Create page** in `app/`:

```tsx
// app/reviews/page.tsx
export default function ReviewsPage() {
  return <div>Reviews Page</div>;
}
```

2. **Add to navigation**
3. **Create API hooks** in `lib/hooks/`
4. **Style with Tailwind**

## Resources

### Documentation

- [Architecture](../docs/ARCHITECTURE.md)
- [Database Schema](../docs/DATABASE-SCHEMA.md)
- [API Documentation](../docs/api/README.md)
- [Environment Variables](../docs/ENVIRONMENT-VARIABLES.md)
- [Troubleshooting](../docs/TROUBLESHOOTING.md)

### External Resources

**Go**:

- [A Tour of Go](https://tour.golang.org/)
- [Effective Go](https://golang.org/doc/effective_go)
- [GORM Documentation](https://gorm.io/docs/)
- [Gin Documentation](https://gin-gonic.com/docs/)

**Next.js**:

- [Next.js Documentation](https://nextjs.org/docs)
- [React Documentation](https://react.dev/)
- [shadcn/ui](https://ui.shadcn.com/)
- [Tailwind CSS](https://tailwindcss.com/docs)

**Database**:

- [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)
- [PostgreSQL Indexes](https://www.postgresql.org/docs/current/indexes.html)

**Docker**:

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

### Team Contacts

- **Tech Lead**: [Name] - tech-lead@niaga.com
- **Backend Lead**: [Name] - backend@niaga.com
- **Frontend Lead**: [Name] - frontend@niaga.com
- **DevOps**: [Name] - devops@niaga.com

### Communication Channels

- **Slack**: #niaga-development
- **Email**: dev-team@niaga.com
- **Meetings**: Daily standup at 10:00 AM
- **Wiki**: [Internal Wiki URL]

## Next Steps

Now that you're set up:

1. ✅ **Completed setup** - Platform running locally
2. 🎯 **Explore the code** - Pick a service to deep dive
3. 📝 **Find a task** - Check GitHub Issues for "good first issue"
4. 💬 **Ask questions** - Reach out on Slack
5. 🚀 **Make your first PR** - Start contributing!

**Welcome aboard! 🎉**

---

**Last Updated**: 2025-12-02  
**Version**: 1.0.0
