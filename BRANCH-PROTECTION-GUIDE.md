# 🔒 Branch Protection Manual Setup Guide

## Why Manual Setup?

Branch protection requires **owner** or **admin** access to the organization. The automated script attempted to setup protection but requires elevated permissions.

---

## Quick Setup Instructions

### For Each Important Repository:

1. Go to: `https://github.com/niaga-platform/REPO-NAME/settings/branches`

2. Click **"Add rule"** or **"Add branch protection rule"**

3. **Branch name pattern:** `main`

4. **Check these settings:**

   - ✅ **Require a pull request before merging**
     - Require approvals: **1**
     - ✅ Dismiss stale pull request approvals when new commits are pushed
   - ✅ **Require status checks to pass before merging** (optional, after CI/CD working)
   - ✅ **Require conversation resolution before merging**
   - ✅ **Include administrators** (optional, if you want rules to apply to you too)

5. Click **"Create"** or **"Save changes"**

---

## Recommended Repositories to Protect

### Critical (High Priority):

- `service-auth` - Authentication service
- `service-catalog` - Product catalog
- `service-order` - Order processing
- `frontend-storefront` - Customer website
- `frontend-admin` - Admin dashboard

### Important (Medium Priority):

- `service-inventory`
- `service-customer`
- `lib-common`
- `lib-ui`

### Optional:

- Other services and frontend apps

---

## Quick Links

**Direct links to settings:**

### Backend Services

- https://github.com/niaga-platform/service-auth/settings/branches
- https://github.com/niaga-platform/service-catalog/settings/branches
- https://github.com/niaga-platform/service-inventory/settings/branches
- https://github.com/niaga-platform/service-order/settings/branches
- https://github.com/niaga-platform/service-customer/settings/branches

### Frontend Apps

- https://github.com/niaga-platform/frontend-storefront/settings/branches
- https://github.com/niaga-platform/frontend-admin/settings/branches

### Libraries

- https://github.com/niaga-platform/lib-common/settings/branches
- https://github.com/niaga-platform/lib-ui/settings/branches

---

## What Branch Protection Does

✅ **Prevents direct pushes to main** - All changes must go through pull requests
✅ **Requires code review** - At least 1 approval needed before merging
✅ **Dismisses stale reviews** - New commits require new approval
✅ **Protects production code** - Prevents accidental breaking changes

---

## Example Workflow with Protection

```bash
# Cannot push directly to main (will be rejected)
git push origin main  # ❌ BLOCKED

# Must use pull request flow
git checkout -b feature/new-feature
git commit -m "Add new feature"
git push origin feature/new-feature

# Then create PR on GitHub
# Get 1 approval
# Merge to main ✅
```

---

## Alternative: Simplified Protection

If full protection is too strict for solo development, use minimal settings:

1. Branch name pattern: `main`
2. Only check: **"Require a pull request before merging"**
3. Set approvals to **0** (allows self-merge but keeps PR history)

This still requires PRs but doesn't require external approvals.

---

## Status Check Integration (Optional)

Once GitHub Actions workflows are running:

1. In branch protection settings
2. Enable: **"Require status checks to pass before merging"**
3. Select checks: **"CI/CD"** or specific workflow names
4. This ensures tests must pass before merging ✅

---

**Note:** Branch protection is optional but highly recommended for production code!
