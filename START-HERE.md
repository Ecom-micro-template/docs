# 🚀 Step-by-Step: Push ke niaga-platform Organization

## Status: Ready to Execute ✅

### Step 1: Login ke GitHub CLI

Buka PowerShell terminal baru dan run:

```powershell
gh auth login
```

**Pilih options berikut:**

1. `? What account do you want to log into?` → **GitHub.com**
2. `? What is your preferred protocol for Git operations?` → **HTTPS**
3. `? Authenticate Git with your GitHub credentials?` → **Yes**
4. `? How would you like to authenticate GitHub CLI?` → **Login with a web browser**
5. Copy code yang keluar (contoh: `XXXX-XXXX`)
6. Press Enter to open browser
7. Paste code dan authorize

---

### Step 2: Create All Repositories

Run automation script:

```powershell
cd c:\Users\DesaMurniLuqman\Desktop\niaga-platform

# Test dulu (dry run)
.\create-github-repos.ps1 -DryRun

# Kalau ok, create for real
.\create-github-repos.ps1
```

**Script akan create 17 repositories:**

- ✅ infra-platform (public)
- ✅ infra-database (private)
- ✅ service-auth (private)
- ✅ service-catalog (private)
- ✅ service-inventory (private)
- ✅ service-order (private)
- ✅ service-customer (private)
- ✅ service-agent (private)
- ✅ service-notification (private)
- ✅ service-reporting (private)
- ✅ frontend-storefront (private)
- ✅ frontend-admin (private)
- ✅ frontend-warehouse (private)
- ✅ frontend-agent (private)
- ✅ lib-common (private)
- ✅ lib-ui (private)
- ✅ niaga-docs (public)

---

### Step 3: Push Local Code to All Repos

Run push automation script:

```powershell
# Test dulu (dry run)
.\push-all-repos.ps1 -DryRun

# Push for real
.\push-all-repos.ps1
```

Script akan:

1. Initialize git dalam setiap folder
2. Create .gitignore yang sesuai (Go/Next.js/Infra)
3. Add remote origin ke niaga-platform organization
4. Commit all changes
5. Push to main branch

**Kalau ada repos yang gagal push:**

```powershell
# Push dengan force (overwrites remote)
.\push-all-repos.ps1 -Force
```

---

### Step 4: Verify

Check organization:

```
https://github.com/orgs/niaga-platform/repositories
```

Should see all 17 repos with code! ✅

---

## Manual Commands (Kalau automation script fail)

### Create Single Repo

```powershell
gh repo create niaga-platform/service-auth --private --description "Authentication Service"
```

### Push Single Repo

```powershell
cd service-auth
git init
git remote add origin https://github.com/niaga-platform/service-auth.git
git add .
git commit -m "Initial commit: Service Auth"
git branch -M main
git push -u origin main
```

---

## Troubleshooting

### "You are not logged into any GitHub hosts"

**Run:** `gh auth login` dan follow prompts

### "Could not create repository"

**Check:** You must be owner/admin of niaga-platform organization

### "fatal: 'origin' already exists"

**Run:** `git remote remove origin` then try again

### "Permission denied (publickey)"

**Use HTTPS instead of SSH**

```powershell
git remote set-url origin https://github.com/niaga-platform/repo-name.git
```

---

**Ready?** Run commands above step by step! 🚀
