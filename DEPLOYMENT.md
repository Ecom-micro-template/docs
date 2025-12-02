# Niaga Platform Deployment Guide

> **Complete Deployment Guide** - Deploy Niaga Platform to production

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Production Deployment](#production-deployment)
  - [Railway Deployment](#railway-deployment)
  - [Netlify Deployment](#netlify-deployment)
  - [VPS Deployment](#vps-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring and Logging](#monitoring-and-logging)
- [Backup and Recovery](#backup-and-recovery)
- [Security Checklist](#security-checklist)

## Overview

The Niaga Platform can be deployed in various configurations:

- **Development**: Docker Compose on local machine
- **Staging/Production**:
  - Backend services → Railway / VPS / AWS ECS
  - Frontend applications → Netlify / Vercel
  - Databases → Managed services (Railway PostgreSQL, Redis Cloud, etc.)

## Prerequisites

### Required Accounts

- [ ] GitHub account (source code)
- [ ] Railway account (backend deployment)
- [ ] Netlify account (frontend deployment)
- [ ] Domain name (optional for custom domain)

### Required Tools

```bash
# Railway CLI
npm install -g @railway/cli

# Netlify CLI
npm install -g netlify-cli
```

## Local Development

### Full Stack with Docker Compose

**Start all services**:

```bash
docker-compose -f docker-compose.dev.yml up -d
```

**Access points**:

- API Gateway: http://localhost:8080
- Storefront: http://localhost:3000
- Admin Panel: http://localhost:3001
- Traefik Dashboard: http://localhost:8081
- PostgreSQL: localhost:5432
- Redis: localhost:6379
- Meilisearch: localhost:7700
- MinIO Console: localhost:9001

**Stop all services**:

```bash
docker-compose -f docker-compose.dev.yml down
```

### Individual Service Development

**Backend (without Docker)**:

```bash
cd service-catalog

# Set environment variables
export DATABASE_URL="postgres://niaga:password@localhost:5432/niaga"
export REDIS_URL="redis://localhost:6379"

# Run service
go run cmd/server/main.go
```

**Frontend (without Docker)**:

```bash
cd frontend-storefront

# Install dependencies
pnpm install

# Set environment
cp .env.example .env.local
# Edit .env.local with API URL

# Run dev server
pnpm dev
```

## Production Deployment

### Railway Deployment

Railway is ideal for deploying backend services with automatic scaling and managed databases.

#### 1. Prepare Services for Railway

Each service needs a `railway.json` (or uses Dockerfile automatically).

**Example railway.json**:

```json
{
  "build": {
    "builder": "DOCKERFILE",
    "dockerfilePath": "Dockerfile"
  },
  "deploy": {
    "startCommand": "./catalog-service",
    "healthcheckPath": "/health",
    "healthcheckTimeout": 30,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
```

#### 2. Create Railway Project

```bash
# Login to Railway
railway login

# Create new project
railway init

# Link to existing project
railway link [project-id]
```

#### 3. Deploy Backend Services

**Deploy single service**:

```bash
cd service-catalog
railway up
```

**Set environment variables**:

```bash
# Via CLI
railway variables set DATABASE_URL="postgres://..."
railway variables set REDIS_URL="redis://..."
railway variables set JWT_SECRET="your-secret-key"

# Or via Railway Dashboard
# https://railway.app/project/[project-id]/service/[service-id]/variables
```

**Required variables per service** (see [ENVIRONMENT-VARIABLES.md](ENVIRONMENT-VARIABLES.md))

#### 4. Provision Managed Databases

**PostgreSQL**:

```bash
# Add PostgreSQL plugin
railway add postgresql

# Railway automatically sets DATABASE_URL
# Available to all services in project
```

**Redis**:

```bash
# Add Redis plugin
railway add redis

# Automatically sets REDIS_URL
```

**MinIO/ S3**:

- Use Railway S3 plugin OR
- Use Cloudflare R2 / AWS S3
- Set `MINIO_*` variables accordingly

**Meilisearch**:

- Deploy separately or use Meilisearch Cloud
- Set `MEILISEARCH_URL` and `MEILISEARCH_KEY`

#### 5. Configure Service URLs

Services need to communicate with each other:

```bash
# Auth service URL (from Railway internal DNS)
railway variables set AUTH_SERVICE_URL="https://service-auth.railway.internal"

# Or use Railway's generated URLs
railway variables set AUTH_SERVICE_URL="https://niaga-auth.up.railway.app"
```

#### 6. Deploy All Services

Create a deployment script:

````yaml
```bash
#!/bin/bash
# deploy-railway.sh

services=("service-auth" "service-catalog" "service-inventory" "service-order" "service-customer" "service-notification" "service-agent" "service-reporting")

for service in "${services[@]}"; do
  echo "Deploying $service..."
  cd $service
  railway up
  cd ..
done

echo "All services deployed!"
````

#### 7. Configure Custom Domain (Optional)

```bash
# In Railway dashboard
# Settings → Domains → Add Custom Domain
# Add: api.yourdomain.com

# Configure DNS
# Add CNAME record:
# api.yourdomain.com → your-project.up.railway.app
```

---

### Netlify Deployment

Netlify is perfect for deploying Next.js frontend applications.

#### 1. Prepare Frontend for Production

**Update environment variables**:

```env
# .env.production
NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api/v1
NEXT_PUBLIC_SITE_URL=https://yourdomain.com
NEXT_PUBLIC_GOOGLE_ANALYTICS_ID=UA-XXXXXXXXX-X
```

**Ensure build works**:

```bash
cd frontend-storefront
pnpm build
```

#### 2. Deploy to Netlify

**Via Netlify CLI**:

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login
netlify login

# Initialize
cd frontend-storefront
netlify init

# Deploy
netlify deploy --prod
```

**Via GitHub Integration**:

1. Connect GitHub repository to Netlify
2. Configure build settings:
   - **Base directory**: `frontend-storefront`
   - **Build command**: `pnpm build`
   - **Publish directory**: `.next`
3. Set environment variables in Netlify dashboard
4. Deploy automatically on push to main

#### 3. Configure Environment Variables

In Netlify Dashboard:

```
Site Settings → Environment Variables

NEXT_PUBLIC_API_URL = https://api.yourdomain.com/api/v1
NEXT_PUBLIC_SITE_URL = https://yourdomain.com
```

#### 4. Deploy All Frontends

Repeat for each frontend:

- `frontend-storefront` → yourdomain.com
- `frontend-admin` → admin.yourdomain.com
- `frontend-warehouse` → warehouse.yourdomain.com
- `frontend-agent` → agent.yourdomain.com

#### 5. Configure Custom Domains

```
Domain Settings → Add Custom Domain
→ yourdomain.com

Configure DNS:
A record: @ → 75.2.60.5
CNAME record: www → your-site.netlify.app
```

---

### VPS Deployment

For full control, deploy to a VPS using Docker Swarm or Kubernetes.

#### Prerequisites

- VPS with Ubuntu 22.04+ (4GB RAM minimum)
- Docker and Docker Compose installed
- Domain name pointed to VPS IP

#### 1. Server Setup

```bash
# SSH into VPS
ssh root@your-server-ip

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose -y

# Create deploy user
adduser deploy
usermod -aG docker deploy
su - deploy
```

#### 2. Clone Repository

```bash
cd /home/deploy
git clone https://github.com/MuhammadLuqman-99/niaga-platform.git
cd niaga-platform
```

#### 3. Configure Production Environment

```bash
# Create production env files
cp docker-compose.dev.yml docker-compose.prod.yml

# Edit with production settings
vim docker-compose.prod.yml

# Set production environment variables
create .env.production file with all secrets
```

**Production docker-compose.yml changes**:

- Remove volume mounts for code (use built images)
- Add restart policies
- Configure resource limits
- Use production environment variables
- Remove debug ports
- Configure SSL certificates for Traefik

#### 4. Setup SSL with Let's Encrypt

Configure Traefik for automatic SSL:

```yaml
# infra-platform/traefik/traefik.prod.yml
entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@yourdomain.com
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web
```

#### 5. Deploy

```bash
# Build and start services
docker-compose -f docker-compose.prod.yml up -d --build

# Check status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

#### 6. Setup Automatic Backups

```bash
# Create backup script
cat > /home/deploy/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/home/deploy/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Backup database
docker exec niaga-postgres pg_dump -U niaga niaga > $BACKUP_DIR/niaga_$DATE.sql

# Backup volumes
docker run --rm \
  -v niaga_postgres_data:/data \
  -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/postgres_data_$DATE.tar.gz /data

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /home/deploy/backup.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add line:
0 2 * * * /home/deploy/backup.sh
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main

jobs:
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Railway
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
        run: |
          npm install -g @railway/cli
          railway up --service service-catalog

  deploy-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Netlify
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
        run: |
          npm install -g pnpm netlify-cli
          cd frontend-storefront
          pnpm install
          pnpm build
          netlify deploy --prod
```

---

## Monitoring and Logging

### Health Checks

All services expose `/health` endpoint:

```bash
curl https://api.yourdomain.com/api/v1/catalog/health
```

### Application Monitoring

**Recommended tools**:

- **Sentry** - Error tracking
- **Datadog** / **New Relic** - APM
- **Grafana Cloud** - Metrics and dashboards

**Setup Sentry**:

```bash
# Add to environment variables
SENTRY_DSN=https://xxx@sentry.io/xxx

# Backend (Go)
go get github.com/getsentry/sentry-go

# Frontend (Next.js)
npm install @sentry/nextjs
```

### Log Aggregation

**Use centralized logging**:

- **Grafana Loki** + **Promtail**
- **ELK Stack** (Elasticsearch, Logstash, Kibana)
- **Cloudflare Logs** / **Datadog Logs**

---

## Backup and Recovery

### Automated Backups

**Database** (PostgreSQL):

```bash
# Daily backup
pg_dump -U niaga niaga | gzip > backup_$(date +%Y%m%d).sql.gz

# Upload to S3
aws s3 cp backup_$(date +%Y%m%d).sql.gz s3://niaga-backups/
```

**File Storage** (MinIO/S3):

- Use built-in S3 replication
- Or use rclone for cross-cloud backup

### Recovery Procedures

**Database restore**:

```bash
# Stop services
docker-compose stop

# Restore database
gunzip < backup_20251202.sql.gz | docker exec -i niaga-postgres psql -U niaga -d niaga

# Restart services
docker-compose start
```

---

## Security Checklist

### Pre-Deployment

- [ ] All environment variables set and secured
- [ ] JWT secret is strong (32+ characters)
- [ ] Database passwords are strong
- [ ] API keys rotated from defaults
- [ ] CORS configured correctly
- [ ] Rate limiting enabled
- [ ] HTTPS/SSL configured
- [ ] Firewall rules configured
- [ ] Database accessible only from app servers
- [ ] Redis secured with password
- [ ] MinIO/S3 buckets are private
- [ ] Secrets not committed to Git

### Post-Deployment

- [ ] Health checks passing
- [ ] SSL certificate valid
- [ ] Logs being collected
- [ ] Monitoring alerts configured
- [ ] Backups running successfully
- [ ] Security headers configured
- [ ] DDoS protection enabled (Cloudflare)
- [ ] Vulnerability scanning (Snyk, Dependabot)

---

## Deployment Checklist

### Before Deploying

- [ ] All tests passing
- [ ] Code reviewed and approved
- [ ] Database migrations tested
- [ ] Environment variables documented
- [ ] Deployment plan reviewed
- [ ] Rollback plan prepared
- [ ] Stakeholders notified

### During Deployment

- [ ] Database backup taken
- [ ] Deploy to staging first
- [ ] Run smoke tests on staging
- [ ] Deploy to production
- [ ] Monitor logs for errors
- [ ] Run health checks
- [ ] Verify critical functionality

### After Deployment

- [ ] Confirm all services running
- [ ] Check error rates
- [ ] Monitor performance metrics
- [ ] Verify backup ran successfully
- [ ] Document any issues
- [ ] Notify team of completion

---

## Troubleshooting Deployment

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed troubleshooting steps.

**Common deployment issues**:

- Environment variables not set
- Database migrations failed
- Service can't connect to dependencies
- SSL certificate issues
- Resource limits exceeded

---

## Related Documentation

- [Environment Variables](ENVIRONMENT-VARIABLES.md)
- [Architecture](ARCHITECTURE.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Developer Onboarding](DEVELOPER-ONBOARDING.md)

---

**Last Updated**: 2025-12-02  
**Version**: 1.0.0
