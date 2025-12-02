# 🚀 Push Niaga Platform ke GitHub Organization

## Organization: https://github.com/niaga-platform

---

## ✅ Step 1: Create Repositories di GitHub

Kita ada 2 options:

### Option A: Guna GitHub CLI (RECOMMENDED - Automatic)

```powershell
# 1. Install GitHub CLI (kalau belum)
# Option 1: Using scoop
scoop install gh

# Option 2: Using winget
winget install --id GitHub.cli

# Option 3: Download installer
# https://cli.github.com/

# 2. Login ke GitHub
gh auth login
# Pilih:
# - GitHub.com
# - HTTPS
# - Login with a web browser

# 3. Create semua repositories automatically
cd c:\Users\DesaMurniLuqman\Desktop\niaga-platform
.\create-github-repos.ps1

# Kalau nak test dulu tanpa create (dry run):
.\create-github-repos.ps1 -DryRun
```

### Option B: Manual Create (if GitHub CLI tak boleh)

Kena create manually 17 repositories kat organization:

**Infrastructure:**

1. https://github.com/organizations/niaga-platform/repositories/new

   - Name: `infra-platform`
   - Description: Infrastructure and DevOps configuration (Docker, Traefik, Monitoring)
   - Private ✅

2. Name: `infra-database`
   - Description: Database migrations, seeds, and schema management
   - Private ✅

**Backend Services:** 3. `service-auth` - Authentication & Authorization Service (Go + Gin) 4. `service-catalog` - Product Catalog Service (Go + Gin) 5. `service-inventory` - Inventory Management Service (Go + Gin) 6. `service-order` - Order Processing Service (Go + Gin) 7. `service-customer` - Customer Management Service (Go + Gin) 8. `service-agent` - Agent & Commission Service (Go + Gin) 9. `service-notification` - Notification Service (Go + Gin) 10. `service-reporting` - Reporting & Analytics Service (Go + Gin)

**Frontend Apps:** 11. `frontend-storefront` - Customer Storefront (Next.js + TypeScript) 12. `frontend-admin` - Admin Dashboard (Next.js + TypeScript) 13. `frontend-warehouse` - Warehouse Management Interface (Next.js) 14. `frontend-agent` - Agent Mobile App PWA (Next.js)

**Libraries:** 15. `lib-common` - Shared Go utilities and helpers 16. `lib-ui` - Shared React UI components

**Documentation:** 17. `niaga-docs` - Platform documentation (Public ✅)

---

## ✅ Step 2: Push Local Code to GitHub

### Automated Push (RECOMMENDED)

```powershell
cd c:\Users\DesaMurniLuqman\Desktop\niaga-platform

# Test dulu (dry run) - tengok apa yang akan jadi
.\push-all-repos.ps1 -DryRun

# Kalau ok, push for real
.\push-all-repos.ps1

# Kalau ada error "failed to push", guna force
.\push-all-repos.ps1 -Force
```

Script akan automatically:

- ✅ Initialize git dalam setiap folder
- ✅ Create .gitignore sesuai dengan type (Go/Next.js/Infra)
- ✅ Add remote origin ke organization repos
- ✅ Commit all changes
- ✅ Push to main branch

### Manual Push (Kalau nak buat satu-satu)

```powershell
# Example untuk service-auth
cd c:\Users\DesaMurniLuqman\Desktop\niaga-platform\service-auth

# Initialize git (kalau belum)
git init

# Add remote
git remote add origin https://github.com/niaga-platform/service-auth.git

# Add files
git add .

# Commit
git commit -m "Initial commit: Service Auth setup"

# Push
git branch -M main
git push -u origin main

# Repeat untuk semua repos...
```

---

## ✅ Step 3: Verify Repos

Check kat GitHub organization:
https://github.com/orgs/niaga-platform/repositories

Should see:

```
✅ infra-platform
✅ infra-database
✅ service-auth
✅ service-catalog
✅ service-inventory
✅ service-order
✅ service-customer
✅ service-agent
✅ service-notification
✅ service-reporting
✅ frontend-storefront
✅ frontend-admin
✅ frontend-warehouse
✅ frontend-agent
✅ lib-common
✅ lib-ui
```

---

## 🎯 Step 4: Organize & Polish

### Add Topics to Repos

**Backend Services:**

```
Topics: go, microservices, gin, ecommerce, niaga-platform, backend
```

**Frontend Apps:**

```
Topics: nextjs, typescript, react, ecommerce, niaga-platform, frontend
```

**Infrastructure:**

```
Topics: docker, traefik, devops, infrastructure, niaga-platform
```

### Enable Branch Protection

For each important repo:

1. Go to Settings → Branches
2. Add rule for `main` branch
3. Enable:
   - ✅ Require a pull request before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require conversation resolution before merging

---

## 🔧 Troubleshooting

### Error: "Repository not found"

**Solution:** Create the repo first di GitHub organization

```powershell
# Using GitHub CLI
gh repo create niaga-platform/repo-name --private

# Or manually: https://github.com/organizations/niaga-platform/repositories/new
```

### Error: "Permission denied"

**Solution:** Make sure you're a member of niaga-platform organization

- Check: https://github.com/orgs/niaga-platform/people
- Invite yourself if needed

### Error: "Authentication failed"

**Solution:** Setup Git credentials

```powershell
# Configure git
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Use Personal Access Token
# Generate at: https://github.com/settings/tokens
# When git asks for password, use token instead
```

### Error: "failed to push some refs"

**Solution 1:** Pull first (if remote has commits)

```powershell
git pull origin main --allow-unrelated-histories
git push -u origin main
```

**Solution 2:** Force push (WARNING: overwrites remote)

```powershell
git push -u origin main --force
```

---

## 📊 Expected Result

After completion, your organization should have:

```
https://github.com/niaga-platform
├── 17 repositories
├── All code pushed
├── README.md in each repo
├── Proper .gitignore files
└── Topics tagged correctly
```

**Next Steps:**

- [ ] Setup GitHub Actions CI/CD
- [ ] Configure deployment secrets
- [ ] Create organization-wide project boards
- [ ] Setup team permissions
- [ ] Document development workflow

---

## 🆘 Need Help?

If automation scripts fail, you can:

1. **Check the log file:**

   ```
   c:\Users\DesaMurniLuqman\Desktop\niaga-platform\push-repos-log.txt
   ```

2. **Push one repo manually** to debug:

   ```powershell
   cd service-catalog
   git remote -v  # Check remote
   git status     # Check status
   git log --oneline -5  # Check commits
   ```

3. **Re-run for specific repos only:**
   Edit `push-all-repos.ps1`, comment out repos that already pushed

---

**Organization:** https://github.com/niaga-platform  
**Last Updated:** 2025-12-01
