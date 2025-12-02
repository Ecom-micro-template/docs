# 🚀 Quick Start: Multi-Repo Setup

## Ringkasan 3 Langkah

### 1️⃣ Create Repositories di GitHub

**Option A: Guna GitHub CLI (Recommended)**
```powershell
# Install GitHub CLI dulu
scoop install gh
# atau
winget install --id GitHub.cli

# Login
gh auth login

# Create semua repos
.\create-github-repos.ps1
```

**Option B: Manual - Create di GitHub Website**
- Pergi: https://github.com/new
- Create repos ikut naming convention:
  - `service-auth`, `service-catalog`, dll
  - `frontend-admin`, `frontend-storefront`, dll
  - `infra-platform`, `infra-database`

---

### 2️⃣ Push Existing Code ke GitHub

```powershell
# Run automation script
.\push-all-repos.ps1

# Atau kalau nak test dulu (dry run):
.\push-all-repos.ps1 -DryRun

# Kalau nak force push:
.\push-all-repos.ps1 -Force
```

**Manual method (untuk single repo):**
```powershell
cd service-auth
git init
git remote add origin https://github.com/MuhammadLuqman-99/service-auth.git
git add .
git commit -m "Initial commit"
git branch -M main
git push -u origin main
```

---

### 3️⃣ Organize & Setup

**Add Topics ke repos:**
- Backend: `go`, `microservices`, `gin`, `ecommerce`, `niaga-platform`
- Frontend: `nextjs`, `typescript`, `react`, `ecommerce`, `niaga-platform`
- Infra: `docker`, `traefik`, `devops`, `infrastructure`

**Setup Branch Protection:**
- Settings → Branches → Add rule
- Branch name: `main`
- ✅ Require pull request before merging
- ✅ Require status checks to pass

---

## 📁 Struktur Repositories

```
GitHub: MuhammadLuqman-99 (atau org name)
│
├── 🏗️ INFRA
│   ├── infra-platform          # Docker, Traefik, Monitoring
│   └── infra-database          # Migrations, Seeds
│
├── 🔧 BACKEND (Go + Gin)
│   ├── service-auth            # Auth service
│   ├── service-catalog         # Products & categories
│   ├── service-inventory       # Stock management
│   ├── service-order           # Orders & cart
│   ├── service-customer        # Customers
│   ├── service-agent           # Agents
│   ├── service-notification    # Notifications
│   └── service-reporting       # Reports
│
├── 🎨 FRONTEND (Next.js)
│   ├── frontend-storefront     # Customer website
│   ├── frontend-admin          # Admin dashboard
│   ├── frontend-warehouse      # WMS
│   └── frontend-agent          # Agent app
│
└── 📦 LIBRARIES
    ├── lib-common              # Go shared code
    └── lib-ui                  # React components
```

---

## 🛠️ Commands Cheat Sheet

### Setup Workspace
```powershell
# Clone all repos
$repos = @("service-auth", "service-catalog", "frontend-admin")
foreach ($repo in $repos) {
    git clone "https://github.com/MuhammadLuqman-99/$repo.git"
}

# Or use VSCode workspace
code niaga-platform.code-workspace
```

### Daily Workflow
```powershell
# Pull latest from all repos
Get-ChildItem -Directory | ForEach-Object {
    cd $_.Name
    git pull
    cd ..
}

# Check status of all repos
Get-ChildItem -Directory | ForEach-Object {
    Write-Host "`n$($_.Name):" -ForegroundColor Cyan
    cd $_.Name
    git status -s
    cd ..
}
```

### Version Management
```powershell
# Tag new release
git tag v1.0.0
git push origin v1.0.0

# List all tags
git tag -l
```

---

## 🔗 Quick Links

### GitHub
- **Repos:** https://github.com/MuhammadLuqman-99?tab=repositories
- **Create New:** https://github.com/new

### Documentation
- Full guide: [`reporoadmap.md`](./reporoadmap.md)
- Automation scripts:
  - [`create-github-repos.ps1`](./create-github-repos.ps1) - Create repos
  - [`push-all-repos.ps1`](./push-all-repos.ps1) - Push code

---

## 🆘 Troubleshooting

### "remote: Repository not found"
```powershell
# Create repo dulu di GitHub, then:
git remote set-url origin https://github.com/MuhammadLuqman-99/repo-name.git
```

### "failed to push some refs"
```powershell
# Force push (WARNING: overwrites remote)
git push -u origin main --force

# Or pull first
git pull origin main --allow-unrelated-histories
git push -u origin main
```

### Permission Denied
```powershell
# Setup Git credentials
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Use Personal Access Token instead of password
# Generate at: https://github.com/settings/tokens
```

---

## ✅ Checklist

**Initial Setup:**
- [ ] GitHub account ready
- [ ] Git installed & configured
- [ ] GitHub CLI installed (optional)
- [ ] All repos created on GitHub
- [ ] Local code pushed to repos

**Organization:**
- [ ] Topics added to all repos
- [ ] README.md in each repo
- [ ] .gitignore configured
- [ ] Branch protection enabled
- [ ] VSCode workspace created

**Next Steps:**
- [ ] Setup CI/CD (GitHub Actions)
- [ ] Configure deployment
- [ ] Document API endpoints
- [ ] Create development guide

---

**Last Updated:** 2025-12-01  
**Version:** 1.0.0
