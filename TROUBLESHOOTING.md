# Niaga Platform Troubleshooting Guide

> **Common Issues and Solutions** - Quick fixes for frequent problems

## Table of Contents

- [General Issues](#general-issues)
- [Database Issues](#database-issues)
- [Service-Specific Issues](#service-specific-issues)
- [Docker and Container Issues](#docker-and-container-issues)
- [Frontend Issues](#frontend-issues)
- [Network and Connectivity](#network-and-connectivity)
- [Performance Issues](#performance-issues)
- [Debugging Tips](#debugging-tips)

## General Issues

### Service Won't Start

**Symptom**: Service crashes immediately or fails to start

**Common Causes**:

1. Missing environment variables
2. Port already in use
3. Database connection failure
4. Dependency service not running

**Solution**:

```bash
# Check service logs
docker-compose -f docker-compose.dev.yml logs service-catalog

# Check if port is in use
netstat -ano | findstr :8002  # Windows
lsof -i :8002                 # Linux/Mac

# Verify environment variables
docker exec niaga-catalog env | grep DATABASE_URL

# Check dependencies are running
docker-compose -f docker-compose.dev.yml ps
```

---

### "Connection Refused" Errors

**Symptom**: Service can't connect to database, Redis, or other services

**Solution**:

```bash
# Check if dependency services are healthy
docker-compose -f docker-compose.dev.yml ps

# Wait for services to be healthy before starting dependent services
docker-compose -f docker-compose.dev.yml up -d postgres redis
# Wait 30 seconds
docker-compose -f docker-compose.dev.yml up -d service-catalog
```

Ensure services use correct hostnames (in Docker: `postgres`, `redis`, not `localhost`).

---

## Database Issues

### "Database Does Not Exist"

**Symptom**: `FATAL: database "niaga" does not exist`

**Solution**:

```bash
# Create database manually
docker exec -it niaga-postgres psql -U niaga -c "CREATE DATABASE niaga;"

# Or restart PostgreSQL container with init script
docker-compose -f docker-compose.dev.yml restart postgres
```

---

### Migration Failures

**Symptom**: Tables not created or migration errors

**Solution**:

```bash
# Drop and recreate database (DEV ONLY!)
docker exec -it niaga-postgres psql -U niaga -c "DROP DATABASE niaga;"
docker exec -it niaga-postgres psql -U niaga -c "CREATE DATABASE niaga;"

# Restart service to re-run migrations
docker-compose -f docker-compose.dev.yml restart service-catalog

# Or run init.sql manually
docker exec -i niaga-postgres psql -U niaga -d niaga < infra-database/seeds/init.sql
```

---

### "Too Many Connections"

**Symptom**: `FATAL: sorry, too many clients already`

**Solution**:

```bash
# Check current connections
docker exec niaga-postgres psql -U niaga -c "SELECT count(*) FROM pg_stat_activity;"

# Increase max_connections in docker-compose.dev.yml
services:
  postgres:
    command: postgres -c max_connections=200

# Or reduce connection pool size in services (config.go)
```

---

### Slow Queries

**Symptom**: Database queries taking too long

**Solution**:

```sql
-- Enable query logging
docker exec niaga-postgres psql -U niaga -c "ALTER SYSTEM SET log_min_duration_statement = 1000;"

-- Check slow queries
docker exec niaga-postgres psql -U niaga -d niaga -c "
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
"

-- Add missing indexes
CREATE INDEX idx_products_category_active ON catalog.products(category_id, is_active);
```

---

## Service-Specific Issues

### Catalog Service

#### Meilisearch Connection Failed

**Symptom**: Search not working, logs show Meilisearch errors

**Solution**:

```bash
# Check Meilisearch is running
curl http://localhost:7700/health

# Check Meilisearch logs
docker logs niaga-meilisearch

# Verify environment variables
MEILISEARCH_URL=http://meilisearch:7700
MEILISEARCH_KEY=niaga_meili_dev_key

# Restart Meilisearch
docker-compose -f docker-compose.dev.yml restart meilisearch
```

#### Image Upload Fails

**Symptom**: 500 error when uploading product images

**Solution**:

```bash
# Check MinIO is running
curl http://localhost:9000/minio/health/live

# Check MinIO browser
http://localhost:9001
# Login: niaga_minio / niaga_minio_password

# Create bucket if missing
docker exec niaga-minio mc mb /data/niaga-catalog

# Verify environment variables
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=niaga_minio
MINIO_SECRET_KEY=niaga_minio_password
MINIO_BUCKET=niaga-catalog
```

---

### Auth Service

#### JWT Token Invalid

**Symptom**: "Invalid or expired token" errors

**Causes**:

1. Token expired (15 min default)
2. JWT_SECRET mismatch between services
3. Malformed token

**Solution**:

```bash
# Ensure all services use same JWT_SECRET
grep JWT_SECRET service-*/.env

# Decode JWT to check contents (jwt.io)
# Verify expiry time (exp claim)

# Use refresh token to get new access token
POST /api/v1/auth/refresh
{
  "refresh_token": "..."
}
```

---

### Order Service

#### Order Creation Fails

**Symptom**: 500 error when creating order

**Common Causes**:

1. Insufficient stock
2. Cart is empty
3. Invalid shipping address
4. Service communication failure

**Solution**:

```bash
# Check order service logs
docker logs niaga-order

# Verify cart has items
GET /api/v1/cart

# Check stock availability
GET /api/v1/inventory/stock?productId={id}

# Verify other services are reachable
docker exec niaga-order ping service-catalog
docker exec niaga-order ping service-inventory
```

---

## Docker and Container Issues

### Container Keeps Restarting

**Symptom**: Container status shows "Restarting"

**Solution**:

```bash
# Check logs for crash reason
docker logs niaga-catalog --tail 100

# Check resource usage
docker stats

# Remove restart policy temporarily for debugging
docker update --restart=no niaga-catalog
docker logs -f niaga-catalog
```

---

### "No Space Left on Device"

**Symptom**: Docker operations fail with disk space errors

**Solution**:

```bash
# Clean up Docker resources
docker system prune -a --volumes

# Remove old images
docker image prune -a

# Remove unused volumes
docker volume prune

# Check disk space
docker system df
```

---

### Port Already in Use

**Symptom**: `bind: address already in use`

**Solution**:

```bash
# Find process using port (Windows)
netstat -ano | findstr :8002
taskkill /PID <PID> /F

# Find and kill process (Linux/Mac)
lsof -i :8002
kill -9 <PID>

# Or change port in docker-compose.dev.yml
ports:
  - "8012:8002"  # Use 8012 externally instead
```

---

##Frontend Issues

### "API Request Failed" / CORS Errors

**Symptom**: Frontend can't reach API, CORS errors in browser console

**Solution**:

```bash
# Verify API is running
curl http://localhost:8080/api/v1/catalog/products

# Check NEXT_PUBLIC_API_URL in frontend .env.local
NEXT_PUBLIC_API_URL=http://localhost:8080/api/v1

# Verify Traefik is routing correctly
curl http://localhost:8080/api/v1/health

# Check Traefik dashboard
http://localhost:8081
```

---

### Build Errors

**Symptom**: `pnpm build` fails

**Common Causes**:

1. TypeScript errors
2. Missing dependencies
3. Environment variable issues

**Solution**:

```bash
# Clear node_modules and reinstall
rm -rf node_modules .next
pnpm install

# Fix TypeScript errors
pnpm lint
pnpm type-check

# Build with verbose output
pnpm build --debug
```

---

### Pages Not Loading

**Symptom**: 404 or blank pages

**Solution**:

```bash
# Check Next.js logs
docker logs niaga-storefront

# Verify pages directory structure
ls -R app/

# Clear .next cache
rm -rf .next
pnpm dev
```

---

## Network and Connectivity

### Services Can't Communicate

**Symptom**: Service A can't reach Service B

**Solution**:

```bash
# Verify all services are on same network
docker network inspect niaga-network

# Test connectivity from one container to another
docker exec niaga-catalog ping niaga-auth
docker exec niaga-catalog curl http://niaga-auth:8001/health

# Check docker-compose network configuration
networks:
  niaga-network:
    driver: bridge
```

---

### Traefik Not Routing

**Symptom**: 404 from API gateway

**Solution**:

```bash
# Check Traefik dashboard
http://localhost:8081

# Verify dynamic configuration
cat infra-platform/traefik/dynamic/*.yml

# Check Traefik logs
docker logs niaga-gateway

# Ensure services have correct labels in docker-compose
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.catalog.rule=PathPrefix(`/api/v1/catalog`)"
```

---

## Performance Issues

### Slow API Responses

**Causes**:

1. Database queries not optimized
2. Missing indexes
3. N+1 query problems
4. No caching

**Solution**:

```bash
# Enable query logging
# Check logs for slow queries

# Add database indexes (see DATABASE-SCHEMA.md)

# Enable Redis caching
# Verify REDIS_URL is set

# Use GORM Preload to avoid N+1
db.Preload("Images").Preload("Variants").Find(&products)
```

###High Memory Usage

**Solution**:

```bash
# Check container memory
docker stats

# Set memory limits in docker-compose.dev.yml
services:
  service-catalog:
    mem_limit: 512m

# Optimize database connection pool
DB_MAX_CONNECTIONS=10
```

---

## Debugging Tips

### Enable Debug Logging

**Go Services**:

```env
LOG_LEVEL=debug
```

**Next.js Apps**:

```env
NODE_ENV=development
```

---

### Access Container Shell

```bash
# Enter running container
docker exec -it niaga-catalog sh

# Check environment variables
env

# Test network connectivity
ping postgres
curl http://redis:6379

# Check files
ls -la
cat config.yaml
```

---

### View All Logs

```bash
# All services
docker-compose -f docker-compose.dev.yml logs -f

# Specific service
docker-compose -f docker-compose.dev.yml logs -f service-catalog

# Last 100 lines
docker logs niaga-catalog --tail 100

# Follow logs
docker logs -f niaga-catalog
```

---

### Database Debugging

```bash
# Connect to PostgreSQL
docker exec -it niaga-postgres psql -U niaga -d niaga

# List schemas
\dn

# List tables in schema
\dt catalog.*

# Describe table
\d catalog.products

# Run query
SELECT * FROM catalog.products LIMIT 5;

# Exit
\q
```

---

### Redis Debugging

```bash
# Connect to Redis
docker exec -it niaga-redis redis-cli

# Check keys
KEYS *

# Get value
GET some_key

# Check info
INFO stats

# Exit
EXIT
```

---

### NATS Debugging

```bash
# Check NATS server info
curl http://localhost:8222/varz

# Check connections
curl http://localhost:8222/connz

#Check subscriptions
curl http://localhost:8222/subsz
```

---

## Common Error Messages

| Error                                     | Cause                | Solution                                 |
| ----------------------------------------- | -------------------- | ---------------------------------------- |
| `dial tcp: lookup postgres: no such host` | Wrong hostname       | Use `postgres` not `localhost` in Docker |
| `pq: password authentication failed`      | Wrong DB password    | Check `DB_PASSWORD` environment variable |
| `bind: address already in use`            | Port conflict        | Change port or kill process using it     |
| `CORS policy` (browser)                   | CORS not configured  | Configure CORS in backend service        |
| `404 Not Found`                           | Route not registered | Check route registration in `main.go`    |
| `500 Internal Server Error`               | Code panic/error     | Check service logs for stack trace       |
| `503Service Unavailable`                  | Service is down      | Check if service container is running    |

---

## Getting Help

If you can't resolve the issue:

1. **Check logs** - Almost always have clues
2. **Search GitHub issues** - Someone may have faced this
3. **Ask in discussions** - Community may help
4. **Create an issue** - With logs and steps to reproduce

### Information to Include

When asking for help, provide:

- Docker/Docker Compose version
- Operating system
- Relevant logs (docker logs)
- Steps to reproduce
- Environment variables (redact secrets!)
- docker-compose ps output

---

## Related Documentation

- [Deployment Guide](DEPLOYMENT.md)
- [Environment Variables](ENVIRONMENT-VARIABLES.md)
- [Architecture](ARCHITECTURE.md)
- [Database Schema](DATABASE-SCHEMA.md)

---

**Last Updated**: 2025-12-02
