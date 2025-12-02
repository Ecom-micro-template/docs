# Environment Variables Reference

> **Complete Environment Variables Guide** - All environment variables for Niaga Platform services

## Table of Contents

- [Overview](#overview)
- [Common Variables](#common-variables)
- [Service-Specific Variables](#service-specific-variables)
- [Infrastructure Variables](#infrastructure-variables)
- [Security Best Practices](#security-best-practices)

## Overview

This document lists all environment variables used across the Niaga Platform. Variables are organized by service and include descriptions, types, default values, and whether they're required.

### Variable Types

- **Required**: Must be set for the service to function
- **Optional**: Has a default value or is only needed in specific scenarios
- **Secret**: Contains sensitive data (passwords, API keys, tokens)

## Common Variables

These variables are used by multiple services:

### Application Configuration

| Variable    | Type    | Required | Default       | Description                                                      |
| ----------- | ------- | -------- | ------------- | ---------------------------------------------------------------- |
| `APP_ENV`   | string  | No       | `development` | Application environment (`development`, `staging`, `production`) |
| `APP_PORT`  | integer | No       | varies        | Port number for the service                                      |
| `LOG_LEVEL` | string  | No       | `info`        | Logging level (`debug`, `info`, `warn`, `error`)                 |

### Database Configuration

| Variable             | Type            | Required | Default     | Description                                                 |
| -------------------- | --------------- | -------- | ----------- | ----------------------------------------------------------- |
| `DATABASE_URL`       | string          | Yes      | -           | Full PostgreSQL connection string                           |
| `DB_HOST`            | string          | Yes\*    | `localhost` | Database host (if not using DATABASE_URL)                   |
| `DB_PORT`            | integer         | Yes\*    | `5432`      | Database port                                               |
| `DB_USER`            | string          | Yes\*    | -           | Database username                                           |
| `DB_PASSWORD`        | string (secret) | Yes\*    | -           | Database password                                           |
| `DB_NAME`            | string          | Yes\*    | -           | Database name                                               |
| `DB_SSLMODE`         | string          | No       | `disable`   | SSL mode (`disable`, `require`, `verify-ca`, `verify-full`) |
| `DB_MAX_CONNECTIONS` | integer         | No       | `20`        | Max database connections in pool                            |

\* Required if `DATABASE_URL` is not provided

### Redis Configuration

| Variable         | Type            | Required | Default     | Description                         |
| ---------------- | --------------- | -------- | ----------- | ----------------------------------- |
| `REDIS_URL`      | string          | Yes      | -           | Full Redis connection URL           |
| `REDIS_HOST`     | string          | Yes\*    | `localhost` | Redis host (if not using REDIS_URL) |
| `REDIS_PORT`     | integer         | Yes\*    | `6379`      | Redis port                          |
| `REDIS_PASSWORD` | string (secret) | No       | -           | Redis password (if auth enabled)    |
| `REDIS_DB`       | integer         | No       | `0`         | Redis database number               |

\* Required if `REDIS_URL` is not provided

### NATS Configuration

| Variable        | Type            | Required | Default                 | Description                     |
| --------------- | --------------- | -------- | ----------------------- | ------------------------------- |
| `NATS_URL`      | string          | Yes      | `nats://localhost:4222` | NATS server URL                 |
| `NATS_USER`     | string          | No       | -                       | NATS username (if auth enabled) |
| `NATS_PASSWORD` | string (secret) | No       | -                       | NATS password (if auth enabled) |

### JWT Configuration

| Variable               | Type            | Required | Default | Description                                      |
| ---------------------- | --------------- | -------- | ------- | ------------------------------------------------ |
| `JWT_SECRET`           | string (secret) | Yes      | -       | Secret key for signing JWT tokens (min 32 chars) |
| `JWT_EXPIRY`           | string          | No       | `15m`   | Access token expiration (e.g., `15m`, `1h`)      |
| `REFRESH_TOKEN_EXPIRY` | string          | No       | `168h`  | Refresh token expiration (default: 7 days)       |

## Service-Specific Variables

### Service: Auth (Port 8001)

| Variable                      | Type    | Required | Default | Description                            |
| ----------------------------- | ------- | -------- | ------- | -------------------------------------- |
| `APP_PORT`                    | integer | No       | `8001`  | HTTP port                              |
| `PASSWORD_HASH_COST`          | integer | No       | `10`    | bcrypt hash cost (10-12 recommended)   |
| `EMAIL_VERIFICATION_REQUIRED` | boolean | No       | `false` | Require email verification             |
| `ALLOWED_ORIGINS`             | string  | No       | `*`     | CORS allowed origins (comma-separated) |

**Example .env**:

```env
APP_ENV=development
APP_PORT=8001
DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
REDIS_URL=redis://redis:6379
JWT_SECRET=your-super-secret-jwt-key-min-32-characters-long
JWT_EXPIRY=15m
REFRESH_TOKEN_EXPIRY=168h
```

---

### Service: Catalog (Port 8002)

| Variable           | Type            | Required | Default         | Description                      |
| ------------------ | --------------- | -------- | --------------- | -------------------------------- |
| `APP_PORT`         | integer         | No       | `8002`          | HTTP port                        |
| `MEILISEARCH_URL`  | string          | Yes      | -               | Meilisearch server URL           |
| `MEILISEARCH_KEY`  | string (secret) | Yes      | -               | Meilisearch master key           |
| `MINIO_ENDPOINT`   | string          | Yes      | -               | MinIO endpoint (without http://) |
| `MINIO_ACCESS_KEY` | string (secret) | Yes      | -               | MinIO access key                 |
| `MINIO_SECRET_KEY` | string (secret) | Yes      | -               | MinIO secret key                 |
| `MINIO_BUCKET`     | string          | Yes      | `niaga-catalog` | MinIO bucket name                |
| `MINIO_USE_SSL`    | boolean         | No       | `false`         | Use SSL for MinIO                |
| `AUTH_SERVICE_URL` | string          | Yes      | -               | Auth service internal URL        |

**Example .env**:

```env
APP_ENV=development
APP_PORT=8002
DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
REDIS_URL=redis://redis:6379
MEILISEARCH_URL=http://meilisearch:7700
MEILISEARCH_KEY=niaga_meili_dev_key
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=niaga_minio
MINIO_SECRET_KEY=niaga_minio_password
MINIO_BUCKET=niaga-catalog
MINIO_USE_SSL=false
NATS_URL=nats://nats:4222
AUTH_SERVICE_URL=http://service-auth:8001
```

---

### Service: Inventory (Port 8003)

| Variable           | Type    | Required | Default | Description               |
| ------------------ | ------- | -------- | ------- | ------------------------- |
| `APP_PORT`         | integer | No       | `8003`  | HTTP port                 |
| `AUTH_SERVICE_URL` | string  | Yes      | -       | Auth service internal URL |

**Example .env**:

```env
APP_ENV=development
APP_PORT=8003
DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
REDIS_URL=redis://redis:6379
NATS_URL=nats://nats:4222
AUTH_SERVICE_URL=http://service-auth:8001
```

---

### Service: Order (Port 8004)

| Variable                | Type    | Required | Default | Description                    |
| ----------------------- | ------- | -------- | ------- | ------------------------------ |
| `APP_PORT`              | integer | No       | `8004`  | HTTP port                      |
| `AUTH_SERVICE_URL`      | string  | Yes      | -       | Auth service internal URL      |
| `CATALOG_SERVICE_URL`   | string  | Yes      | -       | Catalog service internal URL   |
| `INVENTORY_SERVICE_URL` | string  | Yes      | -       | Inventory service internal URL |
| `CUSTOMER_SERVICE_URL`  | string  | Yes      | -       | Customer service internal URL  |

**Example .env**:

```env
APP_ENV=development
APP_PORT=8004
DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
REDIS_URL=redis://redis:6379
NATS_URL=nats://nats:4222
AUTH_SERVICE_URL=http://service-auth:8001
CATALOG_SERVICE_URL=http://service-catalog:8002
INVENTORY_SERVICE_URL=http://service-inventory:8003
CUSTOMER_SERVICE_URL=http://service-customer:8005
```

---

### Service: Customer (Port 8005)

| Variable           | Type    | Required | Default | Description               |
| ------------------ | ------- | -------- | ------- | ------------------------- |
| `APP_PORT`         | integer | No       | `8005`  | HTTP port                 |
| `AUTH_SERVICE_URL` | string  | Yes      | -       | Auth service internal URL |

**Example .env**:

```env
APP_ENV=development
APP_PORT=8005
DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
REDIS_URL=redis://redis:6379
NATS_URL=nats://nats:4222
AUTH_SERVICE_URL=http://service-auth:8001
```

---

### Service: Notification (Port 8006)

| Variable         | Type            | Required | Default          | Description                      |
| ---------------- | --------------- | -------- | ---------------- | -------------------------------- |
| `APP_PORT`       | integer         | No       | `8006`           | HTTP port                        |
| `SMTP_HOST`      | string          | Yes      | -                | SMTP server host                 |
| `SMTP_PORT`      | integer         | Yes      | -                | SMTP server port                 |
| `SMTP_USER`      | string          | No       | -                | SMTP username (if auth required) |
| `SMTP_PASSWORD`  | string (secret) | No       | -                | SMTP password (if auth required) |
| `SMTP_FROM`      | string          | Yes      | -                | Default sender email address     |
| `SMTP_FROM_NAME` | string          | No       | `Niaga Platform` | Default sender name              |

**Example .env (Development)**:

```env
APP_ENV=development
APP_PORT=8006
REDIS_URL=redis://redis:6379
NATS_URL=nats://nats:4222
SMTP_HOST=mailhog
SMTP_PORT=1025
SMTP_FROM=noreply@niaga.local
```

**Example .env (Production)**:

```env
APP_ENV=production
APP_PORT=8006
REDIS_URL=redis://redis:6379
NATS_URL=nats://nats:4222
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASSWORD=SG.your_sendgrid_api_key
SMTP_FROM=noreply@niaga.com
SMTP_FROM_NAME=Niaga Platform
```

---

### Service: Agent (Port 8007)

| Variable           | Type    | Required | Default | Description               |
| ------------------ | ------- | -------- | ------- | ------------------------- |
| `APP_PORT`         | integer | No       | `8007`  | HTTP port                 |
| `AUTH_SERVICE_URL` | string  | Yes      | -       | Auth service internal URL |

**Example .env**:

```env
APP_ENV=development
APP_PORT=8007
DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
REDIS_URL=redis://redis:6379
NATS_URL=nats://nats:4222
AUTH_SERVICE_URL=http://service-auth:8001
```

---

### Service: Reporting (Port 8008)

| Variable           | Type    | Required | Default | Description                                   |
| ------------------ | ------- | -------- | ------- | --------------------------------------------- |
| `APP_PORT`         | integer | No       | `8008`  | HTTP port                                     |
| `AUTH_SERVICE_URL` | string  | Yes      | -       | Auth service internal URL                     |
| `READ_REPLICA_URL` | string  | No       | -       | PostgreSQL read replica URL (for performance) |

**Example .env**:

```env
APP_ENV=development
APP_PORT=8008
DATABASE_URL=postgres://niaga:niaga_dev_password@postgres:5432/niaga?sslmode=disable
REDIS_URL=redis://redis:6379
NATS_URL=nats://nats:4222
AUTH_SERVICE_URL=http://service-auth:8001
```

---

## Frontend Applications

### Frontend: Storefront (Port 3000)

| Variable                          | Type   | Required | Default       | Description                  |
| --------------------------------- | ------ | -------- | ------------- | ---------------------------- |
| `NODE_ENV`                        | string | No       | `development` | Node environment             |
| `NEXT_PUBLIC_API_URL`             | string | Yes      | -             | Public API base URL          |
| `NEXT_PUBLIC_SITE_URL`            | string | Yes      | -             | Public site URL              |
| `NEXT_PUBLIC_GOOGLE_ANALYTICS_ID` | string | No       | -             | Google Analytics tracking ID |

**Example .env.local**:

```env
NODE_ENV=development
NEXT_PUBLIC_API_URL=http://localhost:8080/api/v1
NEXT_PUBLIC_SITE_URL=http://localhost:3000
```

---

### Frontend: Admin Panel (Port 3001)

| Variable               | Type   | Required | Default       | Description         |
| ---------------------- | ------ | -------- | ------------- | ------------------- |
| `NODE_ENV`             | string | No       | `development` | Node environment    |
| `NEXT_PUBLIC_API_URL`  | string | Yes      | -             | Public API base URL |
| `NEXT_PUBLIC_SITE_URL` | string | Yes      | -             | Public site URL     |

**Example .env.local**:

```env
NODE_ENV=development
NEXT_PUBLIC_API_URL=http://localhost:8080/api/v1
NEXT_PUBLIC_SITE_URL=http://localhost:3001
```

---

### Frontend: Warehouse App (Port 3002)

Same as Admin Panel, different port.

---

### Frontend: Agent App (Port 3003)

Same as Admin Panel, different port.

---

## Infrastructure Variables

### Traefik (API Gateway)

Configured via `infra-platform/traefik/traefik.dev.yml` and `docker-compose.dev.yml`.

No environment variables required for development. Production configuration would include:

- SSL certificate paths
- Let's Encrypt configuration
- Rate limiting rules

### PostgreSQL

| Variable            | Description           |
| ------------------- | --------------------- |
| `POSTGRES_USER`     | Database superuser    |
| `POSTGRES_PASSWORD` | Superuser password    |
| `POSTGRES_DB`       | Initial database name |

**Development**:

```env
POSTGRES_USER=niaga
POSTGRES_PASSWORD=niaga_dev_password
POSTGRES_DB=niaga
```

### Redis

Usually no configuration needed for development. Production:

- `REDIS_PASSWORD` - For auth-enabled Redis

### Meilisearch

| Variable           | Description                               |
| ------------------ | ----------------------------------------- |
| `MEILI_MASTER_KEY` | Master API key                            |
| `MEILI_ENV`        | Environment (`development`, `production`) |

**Development**:

```env
MEILI_MASTER_KEY=niaga_meili_dev_key
MEILI_ENV=development
```

### MinIO

| Variable              | Description    |
| --------------------- | -------------- |
| `MINIO_ROOT_USER`     | Admin username |
| `MINIO_ROOT_PASSWORD` | Admin password |

**Development**:

```env
MINIO_ROOT_USER=niaga_minio
MINIO_ROOT_PASSWORD=niaga_minio_password
```

### NATS

Usually no configuration needed. Production:

- Enable authentication with user/password
- Enable TLS

---

## Security Best Practices

### 1. Never Commit Secrets

- Add `.env` to `.gitignore`
- Use `.env.example` as template
- Never hardcode secrets in code

### 2. Use Strong Secrets

**Password/Key Requirements**:

- JWT Secret: Minimum 32 characters, random
- Database Password: Minimum 16 characters
- API Keys: Use provider-generated keys

**Generate Strong Secrets**:

```bash
# Generate 32-character random string
openssl rand -base64 32

# Generate UUID
uuidgen
```

### 3. Environment-Specific Variables

Use different values for each environment:

- Development: Simple, local values
- Staging: Production-like, but separate
- Production: Secure, monitored

### 4. Use Secret Management

For production:

- **Docker Secrets** (Docker Swarm)
- **Kubernetes Secrets** (K8s)
- **HashiCorp Vault**
- **AWS Secrets Manager** / **Azure Key Vault** / **GCP Secret Manager**

### 5. Rotate Secrets Regularly

- JWT Secret: Rotate quarterly
- Database Passwords: Rotate semi-annually
- API Keys: Rotate when compromised

### 6. Minimal Permissions

Grant minimum required permissions:

- Database users: Only access needed schemas
- API keys: Scope to specific resources
- Service accounts: Least privilege principle

---

## Quick Setup

### Development

1. **Copy example files**:

```bash
# Backend services
for service in service-*; do
  cp $service/.env.example $service/.env
done

# Frontend apps
for app in frontend-*; do
  cp $app/.env.example $app/.env.local
done
```

2. **Edit .env files** with local values (usually defaults work)

3. **Start with docker-compose**:

```bash
docker-compose -f docker-compose.dev.yml up -d
```

### Production

1. **Use environment-specific configurations**
2. **Set all required variables** via:
   - Cloud provider environment variables
   - Secret management system
   - Docker secrets
3. **Validate all secrets are set** before deployment

---

## Environment Validation

Each service should validate required environment variables on startup. Missing variables should cause startup failure with clear error messages.

Example validation (Go):

```go
func validateEnv() error {
    required := []string{
        "DATABASE_URL",
        "REDIS_URL",
        "JWT_SECRET",
    }

    for _, key := range required {
        if os.Getenv(key) == "" {
            return fmt.Errorf("required environment variable %s is not set", key)
        }
    }

    return nil
}
```

---

## Related Documentation

- [Deployment Guide](DEPLOYMENT.md) - Deployment instructions
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues
- [Architecture](ARCHITECTURE.md) - System architecture

---

**Last Updated**: 2025-12-02  
**Version**: 1.0.0
