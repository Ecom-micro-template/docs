# 🎯 Repository Organization & CI/CD Setup Guide

## Overview

This guide covers automated setup for:

1. ✅ Repository topics (for better discoverability)
2. ✅ Branch protection rules
3. ✅ GitHub Actions CI/CD workflows

---

## 🏷️ Step 1: Add Topics to Repositories

Topics help organize and discover repositories.

### Automated Setup

```powershell
# Test first (dry run)
.\add-topics.ps1 -DryRun

# Add topics to all repos
.\add-topics.ps1
```

### Topics Added

**Backend Services:**

- `go`, `golang`, `microservices`, `gin`, `niaga-platform`
- Plus service-specific: `authentication`, `ecommerce`, `orders`, etc.

**Frontend Apps:**

- `nextjs`, `react`, `typescript`, `niaga-platform`
- Plus app-specific: `storefront`, `admin-dashboard`, `pwa`, etc.

**Infrastructure:**

- `docker`, `devops`, `infrastructure`, `niaga-platform`

### Manual Alternative

If script fails, add manually:

1. Go to repo: `https://github.com/niaga-platform/REPO-NAME`
2. Click gear icon ⚙️ next to "About"
3. Add topics in text field
4. Save changes

---

## 🔒 Step 2: Setup Branch Protection

Protects `main` branch from accidental changes.

### Automated Setup

```powershell
# Test first (dry run)
.\setup-branch-protection.ps1 -DryRun

# Setup for all important repos
.\setup-branch-protection.ps1

# Setup for specific repos only
.\setup-branch-protection.ps1 -Repos @("service-auth", "service-catalog")
```

### Protection Rules Applied

- ✅ Require pull request before merging
- ✅ Require 1 approval
- ✅ Dismiss stale reviews on new commits
- ✅ Cannot force push to main

### Manual Alternative

If automated setup fails (requires admin access):

1. Go to: `https://github.com/niaga-platform/REPO-NAME/settings/branches`
2. Click "Add rule"
3. Branch name pattern: `main`
4. Check:
   - ✅ Require a pull request before merging
   - ✅ Require approvals (1)
   - ✅ Dismiss stale pull request approvals when new commits are pushed
5. Save changes

---

## ⚙️ Step 3: Setup GitHub Actions CI/CD

Automated testing and deployment workflows.

### Available Workflow Templates

**1. Go Service CI (`go-service-ci.yml`)**

- ✅ Run tests with coverage
- ✅ Lint code with golangci-lint
- ✅ Build binary
- 🐳 Optional: Build Docker image

**2. Next.js CI (`nextjs-ci.yml`)**

- ✅ ESLint check
- ✅ TypeScript type checking
- ✅ Run tests
- ✅ Build application
- 🚀 Optional: Deploy to Vercel

### Automated Setup

```powershell
# Test first (dry run)
.\setup-workflows.ps1 -DryRun

# Copy workflows to all repos
.\setup-workflows.ps1

# Commit and push workflows
.\push-modified.ps1 "Add GitHub Actions CI/CD workflows"
```

### Manual Setup

For a single repository:

```powershell
# Example: service-catalog
cd service-catalog
mkdir .github\workflows
copy ..\.github-templates\go-service-ci.yml .github\workflows\ci.yml

# Customize if needed, then commit
git add .github/
git commit -m "Add CI/CD workflow"
git push origin main
```

### Workflow Customization

Edit `.github/workflows/ci.yml` in each repo to:

**For Go services:**

- Add database for integration tests
- Enable Docker build (uncomment docker job)
- Add deployment step

**For Next.js apps:**

- Configure environment variables
- Enable Vercel deployment (uncomment deploy jobs)
- Add E2E tests with Playwright

### GitHub Secrets (if needed)

Some workflows need secrets. Add them at:
`https://github.com/niaga-platform/REPO-NAME/settings/secrets/actions`

Common secrets:

- `VERCEL_TOKEN` - For Vercel deployment
- `VERCEL_ORG_ID` - Vercel organization ID
- `VERCEL_PROJECT_ID` - Vercel project ID
- `DOCKER_USERNAME` - Docker Hub username
- `DOCKER_TOKEN` - Docker Hub access token

---

## 🎯 Quick Start - Run Everything

```powershell
# 1. Add topics
.\add-topics.ps1

# 2. Setup workflows
.\setup-workflows.ps1

# 3. Push workflows to GitHub
.\push-modified.ps1 "Setup: Add topics and CI/CD workflows"

# 4. Setup branch protection (requires admin)
.\setup-branch-protection.ps1
```

---

## 📊 Verification

### Check Topics

Visit: `https://github.com/orgs/niaga-platform/repositories`

- All repos should have appropriate topics

### Check Workflows

After pushing workflows, check:

1. Go to repo: `https://github.com/niaga-platform/REPO-NAME/actions`
2. Should see "CI/CD" workflow
3. Make a small change and push - workflow should run automatically

### Check Branch Protection

1. Go to: `https://github.com/niaga-platform/REPO-NAME/settings/branches`
2. Should see rule for `main` branch

---

## 🔄 Workflow Triggers

Workflows run automatically on:

- ✅ Push to `main` or `develop` branch
- ✅ Pull request to `main` or `develop`

### Manual Trigger

You can also trigger workflows manually:

1. Go to: `https://github.com/niaga-platform/REPO-NAME/actions`
2. Select workflow
3. Click "Run workflow"

---

## 🐛 Troubleshooting

### Topics Script Fails

**Error:** "gh: command not found"
**Fix:** Make sure GitHub CLI is installed and authenticated

### Branch Protection Fails

**Error:** "403 Forbidden" or "Resource not accessible"
**Fix:** Requires admin access. Setup manually via GitHub UI.

### Workflows Don't Run

**Check:**

1. Workflow file is in `.github/workflows/` directory
2. File has `.yml` extension
3. YAML syntax is valid
4. Branch name matches trigger (main/develop)

### Build Fails in Workflow

**Common issues:**

- Missing dependencies in go.mod or package.json
- Environment variables not set
- Tests failing

**Fix:** Check workflow logs at:
`https://github.com/niaga-platform/REPO-NAME/actions`

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)
- [Repository Topics](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics)

---

## ✅ Checklist

- [ ] Topics added to all repositories
- [ ] GitHub Actions workflows added
- [ ] Workflows committed and pushed
- [ ] First workflow run successful
- [ ] Branch protection enabled (optional)
- [ ] Secrets configured (if needed)

---

**Organization:** https://github.com/niaga-platform  
**Actions:** https://github.com/niaga-platform/REPO-NAME/actions
