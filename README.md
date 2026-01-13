# Ecom Micro Template

E-commerce microservices template - ready for any business.

## Repositories

### Backend Services (Go)
| Service | Port | Description |
|---------|------|-------------|
| service-auth | 8001 | Authentication & JWT |
| template-service-go | 8000 | Product catalog |
| service-order | 8002 | Order management |
| service-inventory | 8003 | Stock & warehouses |
| service-customer | 8004 | Customer profiles |
| service-agent | 8005 | Sales agents |
| service-notification | 8006 | Email & alerts |
| service-reporting | 8007 | Analytics |
| service-support | 8008 | Helpdesk |
| service-marketplace | 8009 | Marketplace sync |

### Frontend Apps (Next.js)
| App | Port | Description |
|-----|------|-------------|
| template-frontend-nextjs | 3001 | Admin dashboard |
| frontend-storefront | 3000 | Customer store |
| frontend-agent | 3002 | Agent portal |
| frontend-warehouse | 3003 | Warehouse app |

### Libraries
| Library | Description |
|---------|-------------|
| lib-common-go | Shared Go middleware |
| lib-ui-react | Shared React components |

### Infrastructure
| Repo | Description |
|------|-------------|
| infra-docker | Docker Compose & Nginx |
| infra-database | Database migrations |

## Quick Start

```bash
# Clone infra and start services
git clone https://github.com/Ecom-micro-template/infra-docker.git
cd infra-docker
cp .env.example .env
docker compose up -d
```

## Tech Stack

- **Backend**: Go 1.24, Gin, GORM
- **Frontend**: Next.js 14, TypeScript, Tailwind
- **Database**: PostgreSQL
- **Cache**: Redis
- **Search**: Meilisearch
- **Storage**: MinIO
- **Events**: NATS JetStream
- **Proxy**: Nginx

## License

MIT

---

https://github.com/Ecom-micro-template
