# 🚀 Daily Workflow Guide - Multi-Repo Development

## Quick Commands Reference

### 📊 Check Status of All Repos

```powershell
.\check-status.ps1
```

Shows which repos have uncommitted changes.

---

### 📤 Push Single Repository

```powershell
.\push-repo.ps1 service-catalog "Add product filtering feature"
```

**Examples:**

```powershell
# Push service-auth changes
.\push-repo.ps1 service-auth "Fix login validation"

# Push frontend-admin changes
.\push-repo.ps1 frontend-admin "Update product management UI"

# Push multiple repos (run separately)
.\push-repo.ps1 service-catalog "Add categories API"
.\push-repo.ps1 frontend-admin "Integrate categories in UI"
```

---

### 📦 Push All Modified Repos (Auto-detect)

```powershell
.\push-modified.ps1 "Daily updates"
```

This will:

1. Check ALL repos for changes
2. Automatically commit & push repos that have changes
3. Skip repos with no changes

---

## 📝 Typical Daily Workflow

### Scenario 1: Working on Single Service

```powershell
# 1. Edit files in service-catalog
# 2. Check what changed
cd service-catalog
git status

# 3. Push using helper script
cd ..
.\push-repo.ps1 service-catalog "Add new product endpoints"
```

---

### Scenario 2: Working on Multiple Services

```powershell
# Edit files in multiple folders:
# - service-catalog
# - frontend-admin
# - lib-common

# Option A: Push each separately
.\push-repo.ps1 service-catalog "Backend: Add product API"
.\push-repo.ps1 frontend-admin "Frontend: Product management UI"
.\push-repo.ps1 lib-common "Shared: Add product types"

# Option B: Push all at once
.\push-modified.ps1 "Feature: Product management complete"
```

---

### Scenario 3: End of Day Commit

```powershell
# Check what you've changed today
.\check-status.ps1

# Push everything
.\push-modified.ps1 "EOD: $(Get-Date -Format 'yyyy-MM-dd')"
```

---

## 🔄 Pull Latest Changes

### Pull Single Repo

```powershell
cd service-catalog
git pull origin main
cd ..
```

### Pull All Repos

```powershell
Get-ChildItem -Directory | ForEach-Object {
    if (Test-Path "$($_.Name)\.git") {
        Write-Host "`nPulling $($_.Name)..." -ForegroundColor Cyan
        cd $_.Name
        git pull
        cd ..
    }
}
```

---

## 🌿 Branching (Advanced)

### Create Feature Branch

```powershell
cd service-catalog
git checkout -b feature/advanced-search
# Make changes
git add .
git commit -m "Add advanced search"
git push -u origin feature/advanced-search
cd ..
```

### Merge Back to Main

```powershell
cd service-catalog
git checkout main
git merge feature/advanced-search
git push origin main
cd ..
```

---

## 🆘 Common Issues

### "Repository not found" error

**Fix:** Make sure you're in the base directory

```powershell
cd c:\Users\DesaMurniLuqman\Desktop\niaga-platform
```

### "Nothing to commit"

**Check:** Run `git status` to see if changes exist

```powershell
cd service-catalog
git status
```

### Accidentally committed wrong files

**Undo last commit (keep changes):**

```powershell
git reset --soft HEAD~1
```

### Need to overwrite remote (careful!)

```powershell
git push origin main --force
```

---

## 📋 Scripts Summary

| Script              | Purpose                     | Usage                                 |
| ------------------- | --------------------------- | ------------------------------------- |
| `check-status.ps1`  | Check all repos for changes | `.\check-status.ps1`                  |
| `push-repo.ps1`     | Push single repo            | `.\push-repo.ps1 repo-name "message"` |
| `push-modified.ps1` | Push all modified repos     | `.\push-modified.ps1 "message"`       |
| `verify-repos.ps1`  | Verify file count           | `.\verify-repos.ps1`                  |

---

## 🎯 Best Practices

1. **Commit Often** - Don't wait too long to commit
2. **Descriptive Messages** - Write clear commit messages
3. **Check Status** - Run `check-status.ps1` before end of day
4. **Pull Before Push** - Always pull latest before pushing (if working in team)
5. **One Feature = One Commit** - Keep commits focused

---

## 📱 Quick Reference Card

```powershell
# Daily routine
.\check-status.ps1                              # What did I change?
.\push-repo.ps1 service-auth "Fix bug"         # Push one repo
.\push-modified.ps1 "Daily work"                # Push all changes

# When starting work
cd service-catalog
git pull origin main                            # Get latest

# View on GitHub
gh repo view niaga-platform/service-catalog --web
```

---

**Organization:** https://github.com/niaga-platform  
**All Repos:** https://github.com/orgs/niaga-platform/repositories
