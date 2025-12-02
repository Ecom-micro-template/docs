# 🗂️ Niaga Platform - Multi-Repo Organization Guide

> **Panduan lengkap untuk organize multi-repository di GitHub**

---

## 📋 Table of Contents

1. [Kenapa Multi-Repo?](#kenapa-multi-repo)
2. [GitHub Organization Strategy](#github-organization-strategy)
3. [Repository Structure](#repository-structure)
4. [Naming Conventions](#naming-conventions)
5. [Setup Steps](#setup-steps)
6. [Best Practices](#best-practices)
7. [Tools & Automation](#tools--automation)

---

## 🤔 Kenapa Multi-Repo?

### Kelebihan Multi-Repo untuk Niaga Platform:

✅ **Independent Deployment** - Setiap service boleh deploy berasingan  
✅ **Team Autonomy** - Different teams boleh work on different repos  
✅ **Clear Boundaries** - Separation of concerns yang jelas  
✅ **Scalability** - Mudah nak scale team dan codebase  
✅ **Security** - Fine-grained access control  
✅ **CI/CD Efficiency** - Only build & deploy what changed  

### Kekurangan (yang perlu handle):

⚠️ **Coordination** - Kena coordinate changes across repos  
⚠️ **Versioning** - Perlu track compatibility versions  
⚠️ **Shared Code** - Need strategy for shared libraries  

---

## 🏢 GitHub Organization Strategy

### Option 1: GitHub Organization (RECOMMENDED ✨)

**Create organization:** `niaga-platform` atau `{company-name}`

**Kelebihan:**
- Professional appearance
- Better team management
- Unlimited public repos (free)
- Easier to manage access control
- Can have multiple teams (Backend, Frontend, DevOps)

**Setup:**
1. Go to: https://github.com/organizations/plan
2. Choose "Create a free organization"
3. Organization name: `niaga-platform`
4. Contact email: your business email
5. Organization belongs to: "My personal account" atau "My business"

### Option 2: Personal Account with Topic Tags

Jika tak mahu organization, boleh guna personal account tapi organize dengan:
- Consistent naming prefix: `niaga-platform-{name}`
- GitHub Topics untuk grouping
- GitHub Project boards untuk track progress

---

## 📁 Repository Structure

### Recommended Multi-Repo Layout

```
GitHub Organization: niaga-platform
│
├── 🏗️ INFRASTRUCTURE REPOS
│   ├── infra-platform              ⭐ Main infrastructure repo
│   │   - Docker configs
│   │   - Traefik setup
│   │   - Monitoring (Grafana, Prometheus)
│   │   - Scripts & automation
│   │   - docker-compose files
│   │
│   └── infra-database             ⭐ Database repo
│       - Migrations
│       - Seeds
│       - Schema documentation
│       - Backup scripts
│
├── 🔧 BACKEND SERVICE REPOS
│   ├── service-auth               ⭐ Authentication service
│   ├── service-catalog            ⭐ Product catalog service
│   ├── service-inventory          ⭐ Inventory management
│   ├── service-order              ⭐ Order processing
│   ├── service-customer           ⭐ Customer management
│   ├── service-agent              ⭐ Agent & commission
│   ├── service-notification       ⭐ Notifications (email/SMS)
│   └── service-reporting          ⭐ Analytics & reports
│
├── 🎨 FRONTEND REPOS
│   ├── frontend-storefront        ⭐ Customer-facing website
│   ├── frontend-admin             ⭐ Admin dashboard
│   ├── frontend-warehouse         ⭐ WMS interface
│   └── frontend-agent             ⭐ Agent mobile app (PWA)
│
├── 📦 SHARED LIBRARY REPOS
│   ├── lib-common                 ⭐ Shared Go utilities
│   ├── lib-proto                  ⭐ gRPC proto files (optional)
│   └── lib-ui                     ⭐ Shared React components
│
└── 📚 DOCUMENTATION REPOS
    ├── niaga-docs                 ⭐ Main documentation
    │   - API documentation
    │   - Architecture diagrams
    │   - Deployment guides
    │   - Development setup
    │
    └── niaga-platform             ⭐ Monorepo coordinator (optional)
        - Overview README
        - Links to all repos
        - Global issues tracking
        - Release notes
```

---

## 🏷️ Naming Conventions

### Repository Names

**Format:** `{prefix}-{type}-{name}`

**Examples:**

#### Infrastructure:
- `infra-platform` ✅
- `infra-database` ✅
- `infra-monitoring` ✅

#### Backend Services:
- `service-auth` ✅
- `service-catalog` ✅
- `service-order` ✅
- `service-{name}` ✅

#### Frontend Apps:
- `frontend-storefront` ✅
- `frontend-admin` ✅
- `frontend-{app-name}` ✅

#### Libraries:
- `lib-common` ✅
- `lib-ui` ✅
- `lib-{purpose}` ✅

#### Avoid:
- ❌ `NiagaPlatform` (PascalCase)
- ❌ `niaga_platform` (snake_case)
- ❌ `my-awesome-service` (unclear)
- ❌ Random names without prefix

### Branch Names

```bash
# Feature branches
feature/user-authentication
feature/product-search
feature/checkout-flow

# Bugfix branches
bugfix/login-validation
fix/cart-calculation

# Hotfix branches (production)
hotfix/payment-gateway
hotfix/critical-security-fix

# Release branches
release/v1.0.0
release/v1.1.0

# Environment branches
main          # Production-ready code
develop       # Development/staging
staging       # Pre-production testing
```

### Tag/Release Naming

```bash
# Semantic versioning
v1.0.0        # Major release
v1.1.0        # Minor release
v1.1.1        # Patch release

# Pre-releases
v2.0.0-alpha.1
v2.0.0-beta.1
v2.0.0-rc.1
```

---

## 🚀 Setup Steps

### Step 1: Create GitHub Organization

```bash
# Via GitHub Web UI:
1. Go to https://github.com/organizations/plan
2. Click "Create a free organization"
3. Enter organization name: niaga-platform
4. Enter contact email
5. Choose organization type
6. Complete setup
```

### Step 2: Create Teams (Optional but Recommended)

```
Organization Settings → Teams → New Team

Teams to create:
├── @backend-team       # Backend developers
├── @frontend-team      # Frontend developers
├── @devops-team        # DevOps/Infrastructure
├── @fullstack-team     # Full-stack developers
└── @leads              # Tech leads/architects
```

### Step 3: Create Repositories

#### Option A: Create via GitHub UI

```
Organization → Repositories → New Repository

For each repo:
1. Owner: niaga-platform
2. Repository name: service-auth (example)
3. Description: "Authentication & Authorization Service"
4. Public or Private (recommend Private for production)
5. Initialize with README: ✅
6. Add .gitignore: Go (for backend) / Node (for frontend)
7. Choose license: MIT or your company license
```

#### Option B: Create via GitHub CLI

```bash
# Install GitHub CLI first
# Windows: scoop install gh
# Or download from: https://cli.github.com/

# Login
gh auth login

# Create organization repos
gh repo create niaga-platform/infra-platform --public --description "Infrastructure and DevOps"
gh repo create niaga-platform/infra-database --public --description "Database migrations and seeds"

# Backend services
gh repo create niaga-platform/service-auth --private --description "Authentication Service"
gh repo create niaga-platform/service-catalog --private --description "Product Catalog Service"
gh repo create niaga-platform/service-inventory --private --description "Inventory Management Service"
gh repo create niaga-platform/service-order --private --description "Order Processing Service"
gh repo create niaga-platform/service-customer --private --description "Customer Management Service"
gh repo create niaga-platform/service-agent --private --description "Agent & Commission Service"
gh repo create niaga-platform/service-notification --private --description "Notification Service"
gh repo create niaga-platform/service-reporting --private --description "Reporting & Analytics Service"

# Frontend apps
gh repo create niaga-platform/frontend-storefront --private --description "Customer Storefront (Next.js)"
gh repo create niaga-platform/frontend-admin --private --description "Admin Dashboard (Next.js)"
gh repo create niaga-platform/frontend-warehouse --private --description "Warehouse Management Interface"
gh repo create niaga-platform/frontend-agent --private --description "Agent Mobile App (PWA)"

# Shared libraries
gh repo create niaga-platform/lib-common --private --description "Shared Go utilities and helpers"
gh repo create niaga-platform/lib-ui --private --description "Shared React UI components"

# Documentation
gh repo create niaga-platform/niaga-docs --public --description "Platform documentation"
```

### Step 4: Initialize and Push Existing Code

```bash
# Untuk setiap folder service/frontend yang dah ada

# Example: service-auth
cd c:\Users\DesaMurniLuqman\Desktop\niaga-platform\service-auth

# Initialize git (if not already)
git init

# Add remote (guna organization repo)
git remote add origin https://github.com/niaga-platform/service-auth.git

# Create .gitignore
# (copy appropriate template from GitHub)

# First commit
git add .
git commit -m "Initial commit: Service Auth setup"

# Push to GitHub
git branch -M main
git push -u origin main

# Repeat untuk semua repos:
# - service-catalog
# - service-inventory
# - frontend-admin
# - etc.
```

### Automated Script untuk Push All Repos

```powershell
# save as: push-all-repos.ps1
# Run from: c:\Users\DesaMurniLuqman\Desktop\niaga-platform

$orgName = "niaga-platform"
$basePath = "c:\Users\DesaMurniLuqman\Desktop\niaga-platform"

# List of directories to push
$repos = @(
    "infra-platform",
    "infra-database",
    "service-auth",
    "service-catalog",
    "service-inventory",
    "service-order",
    "service-customer",
    "service-agent",
    "service-notification",
    "service-reporting",
    "frontend-storefront",
    "frontend-admin",
    "frontend-warehouse",
    "frontend-agent",
    "lib-common",
    "lib-ui"
)

foreach ($repo in $repos) {
    $repoPath = Join-Path $basePath $repo
    
    if (Test-Path $repoPath) {
        Write-Host "Processing: $repo" -ForegroundColor Green
        
        Set-Location $repoPath
        
        # Initialize git if needed
        if (-not (Test-Path ".git")) {
            git init
        }
        
        # Add remote
        git remote remove origin 2>$null
        git remote add origin "https://github.com/$orgName/$repo.git"
        
        # Add all files
        git add .
        
        # Commit
        git commit -m "Initial commit: $repo setup"
        
        # Push
        git branch -M main
        git push -u origin main --force
        
        Write-Host "Completed: $repo`n" -ForegroundColor Cyan
    } else {
        Write-Host "Skipped (not found): $repo" -ForegroundColor Yellow
    }
}

Set-Location $basePath
Write-Host "`nAll repositories processed!" -ForegroundColor Green
```

---

## 💡 Best Practices

### 1. Repository README Standards

**Every repo must have:**

```markdown
# {Service/App Name}

> Brief description

## 🚀 Quick Start

## 📋 Prerequisites

## 🛠️ Installation

## 🏃 Running

## 🧪 Testing

## 📦 Building

## 🚢 Deployment

## 🔗 Related Repositories

## 📝 License
```

### 2. Use GitHub Topics for Discovery

**Add topics to each repo:**

Backend services:
```
Topics: go, microservices, gin, ecommerce, niaga-platform, backend
```

Frontend apps:
```
Topics: nextjs, typescript, react, ecommerce, niaga-platform, frontend
```

Infrastructure:
```
Topics: docker, traefik, devops, infrastructure, niaga-platform
```

### 3. Cross-Repository Documentation

Create a **"coordinator" repo** or use GitHub Wiki:

**niaga-platform** (main repo):
```
README.md - Platform overview with links to all repos
ARCHITECTURE.md - System architecture
CONTRIBUTING.md - Contribution guidelines
CHANGELOG.md - Platform-wide changes
```

### 4. Dependency Management

**For shared libraries:**

```go
// In go.mod of services
module github.com/niaga-platform/service-auth

require (
    github.com/niaga-platform/lib-common v1.2.3
)
```

```json
// In package.json of frontends
{
  "dependencies": {
    "@niaga-platform/lib-ui": "^1.2.0"
  }
}
```

### 5. Version Compatibility Matrix

Maintain in main docs repo:

```markdown
## Version Compatibility

| Platform Version | service-auth | service-catalog | frontend-admin |
|-----------------|--------------|-----------------|----------------|
| v1.0.0          | v1.0.0       | v1.0.0          | v1.0.0         |
| v1.1.0          | v1.1.0       | v1.0.1          | v1.1.0         |
| v2.0.0          | v2.0.0       | v2.0.0          | v2.0.0         |
```

### 6. GitHub Projects for Coordination

**Create organization-wide project board:**

```
Organization → Projects → New Project

Columns:
├── 📥 Backlog
├── 📋 To Do
├── 🏗️ In Progress
├── 👀 Review
├── ✅ Done
└── 🚀 Deployed
```

Link issues from multiple repos to single project board.

### 7. GitHub Actions Workflows

**Standardize CI/CD across repos:**

```yaml
# .github/workflows/ci.yml (backend services)
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.22'
      - run: go test ./...
      - run: go build ./...
```

```yaml
# .github/workflows/ci.yml (frontend apps)
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run build
      - run: npm test
```

---

## 🛠️ Tools & Automation

### 1. Meta Repository Tool

**Option A: Use Git Submodules** (NOT recommended for mono-to-multi migration)

**Option B: Custom Scripts**

Create `dev-setup.sh`:

```bash
#!/bin/bash

# Clone all repositories
ORG="niaga-platform"
REPOS=(
    "infra-platform"
    "service-auth"
    "service-catalog"
    "frontend-admin"
    # ... add all repos
)

mkdir -p ~/niaga-workspace
cd ~/niaga-workspace

for repo in "${REPOS[@]}"; do
    if [ ! -d "$repo" ]; then
        git clone "https://github.com/$ORG/$repo.git"
    else
        echo "Skipping $repo (already exists)"
    fi
done

echo "All repositories cloned!"
```

### 2. Automated Version Bumping

```bash
#!/bin/bash
# bump-version.sh

NEW_VERSION=$1

if [ -z "$NEW_VERSION" ]; then
    echo "Usage: ./bump-version.sh v1.2.3"
    exit 1
fi

# Update all service versions
for service in service-*; do
    cd $service
    git tag $NEW_VERSION
    git push origin $NEW_VERSION
    cd ..
done
```

### 3. Repository Health Checks

```powershell
# check-repos.ps1
# Checks if all repos are up to date

$repos = Get-ChildItem -Directory
foreach ($repo in $repos) {
    Set-Location $repo.Name
    Write-Host "`nChecking: $($repo.Name)" -ForegroundColor Cyan
    
    git fetch
    $status = git status -uno
    if ($status -match "behind") {
        Write-Host "  ⚠️  Behind remote" -ForegroundColor Yellow
    } elseif ($status -match "ahead") {
        Write-Host "  ⬆️  Ahead of remote" -ForegroundColor Blue
    } else {
        Write-Host "  ✅ Up to date" -ForegroundColor Green
    }
    
    Set-Location ..
}
```

### 4. VSCode Multi-Root Workspace

Create `niaga-platform.code-workspace`:

```json
{
  "folders": [
    { "path": "infra-platform" },
    { "path": "service-auth" },
    { "path": "service-catalog" },
    { "path": "service-inventory" },
    { "path": "frontend-admin" },
    { "path": "frontend-storefront" },
    { "path": "lib-common" }
  ],
  "settings": {
    "editor.formatOnSave": true,
    "go.formatTool": "goimports",
    "typescript.preferences.importModuleSpecifier": "relative"
  }
}
```

Open in VSCode:
```bash
code niaga-platform.code-workspace
```

---

## 📊 Repository Organization Visualization

```
GitHub Organization: niaga-platform
├── 👥 Teams
│   ├── @backend-team (service-* repos)
│   ├── @frontend-team (frontend-* repos)
│   ├── @devops-team (infra-* repos)
│   └── @leads (all repos)
│
├── 📁 Repositories (20 repos)
│   ├── Infrastructure (2)
│   ├── Backend Services (8)
│   ├── Frontend Apps (4)
│   ├── Shared Libraries (3)
│   └── Documentation (3)
│
├── 🎯 Projects (Organization-wide boards)
│   ├── Platform Roadmap
│   ├── Current Sprint
│   └── Bug Tracking
│
└── 🔐 Settings
    ├── Member privileges
    ├── Repository defaults
    ├── Security policies
    └── Secrets management
```

---

## 🎯 Summary Checklist

### Setup Checklist:

- [ ] Create GitHub Organization `niaga-platform`
- [ ] Create teams (@backend-team, @frontend-team, @devops-team)
- [ ] Create all 20+ repositories with proper naming
- [ ] Setup repository templates (README, .gitignore, LICENSE)
- [ ] Initialize and push existing code to repos
- [ ] Add GitHub Topics to all repos
- [ ] Create organization-wide project boards
- [ ] Setup GitHub Actions CI/CD for each repo
- [ ] Create main documentation repo with architecture
- [ ] Setup VSCode multi-root workspace
- [ ] Create automation scripts (push-all, bump-version, etc.)
- [ ] Document version compatibility matrix
- [ ] Setup branch protection rules (main, develop)
- [ ] Configure repository access controls
- [ ] Create CONTRIBUTING.md guidelines

---

## 🔗 Quick Links

Once setup, your organization will look like:

- **Organization:** https://github.com/niaga-platform
- **Repos:** https://github.com/niaga-platform?type=all
- **Teams:** https://github.com/orgs/niaga-platform/teams
- **Projects:** https://github.com/orgs/niaga-platform/projects
- **Packages:** https://github.com/orgs/niaga-platform/packages

---

## 📚 Additional Resources

- [GitHub Organizations Documentation](https://docs.github.com/en/organizations)
- [Managing Teams](https://docs.github.com/en/organizations/organizing-members-into-teams)
- [Monorepo vs Multi-Repo](https://github.com/joelparkerhenderson/monorepo-vs-polyrepo)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Last Updated:** 2025-12-01  
**Author:** Niaga Platform Team  
**Version:** 1.0.0
