# Phase 5: RBAC System Verification Script
# Tests all Role-Based Access Control endpoints and permission checking

param(
    [string]$ApiBaseUrl = "http://localhost:8082/api/v1",
    [string]$AdminEmail = "admin@kilangdesamurnibatik.com",
    [string]$AdminPassword = "Admin123!@#"
)

$ErrorActionPreference = "Continue"

# Color output functions
function Write-Success { param($msg) Write-Host "[PASS] $msg" -ForegroundColor Green }
function Write-Failure { param($msg) Write-Host "[FAIL] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Section { param($msg) Write-Host "`n=== $msg ===" -ForegroundColor Yellow }

# Global auth token
$script:AuthToken = ""

# Helper function to make authenticated requests
function Invoke-AuthenticatedRequest {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [switch]$ExpectForbidden
    )
    
    $headers = @{
        "Authorization" = "Bearer $script:AuthToken"
        "Content-Type" = "application/json"
    }
    
    $uri = "$ApiBaseUrl$Endpoint"
    
    try {
        $params = @{
            Method = $Method
            Uri = $uri
            Headers = $headers
            ErrorAction = "Stop"
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        
        if ($ExpectForbidden) {
            Write-Failure "Expected 403 Forbidden but got success for $Endpoint"
            return $null
        }
        
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        
        if ($ExpectForbidden -and $statusCode -eq 403) {
            Write-Success "Correctly received 403 Forbidden for $Endpoint"
            return $null
        }
        
        if ($statusCode -eq 401) {
            Write-Failure "Unauthorized (401) for $Endpoint - Token may be expired"
        }
        elseif ($statusCode -eq 403) {
            Write-Failure "Forbidden (403) for $Endpoint - Missing permissions"
        }
        elseif ($statusCode -eq 404) {
            Write-Failure "Not Found (404) for $Endpoint"
        }
        else {
            Write-Failure "Error ($statusCode) for $Endpoint : $_"
        }
        
        return $null
    }
}

# Test Results Tracking
$script:Results = @{
    Passed = 0
    Failed = 0
    Tests = @()
}

function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    if ($Passed) {
        $script:Results.Passed++
        Write-Success "$TestName"
    }
    else {
        $script:Results.Failed++
        Write-Failure "$TestName - $Details"
    }
    
    $script:Results.Tests += @{
        Name = $TestName
        Passed = $Passed
        Details = $Details
    }
}

Write-Section "Phase 5: RBAC System Verification"
Write-Info "API Base URL: $ApiBaseUrl"
Write-Info "Test Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# ========================================
# 1. Authentication Test
# ========================================
Write-Section "1. Authentication"

try {
    $loginBody = @{
        email = $AdminEmail
        password = $AdminPassword
    }
    
    $loginResponse = Invoke-RestMethod -Method POST -Uri "$ApiBaseUrl/auth/login" `
        -Body ($loginBody | ConvertTo-Json) -ContentType "application/json" -ErrorAction Stop
    
    if ($loginResponse.token) {
        $script:AuthToken = $loginResponse.token
        Add-TestResult -TestName "Admin Login" -Passed $true
        Write-Info "Token obtained successfully"
    }
    else {
        Add-TestResult -TestName "Admin Login" -Passed $false -Details "No token in response"
        Write-Failure "Cannot continue without auth token"
        exit 1
    }
}
catch {
    Add-TestResult -TestName "Admin Login" -Passed $false -Details $_.Exception.Message
    Write-Failure "Login failed: $_"
    exit 1
}

# ========================================
# 2. Current User / Me Endpoint
# ========================================
Write-Section "2. Current User Profile"

$meResponse = Invoke-AuthenticatedRequest -Method GET -Endpoint "/auth/me"
if ($meResponse) {
    Add-TestResult -TestName "GET /auth/me" -Passed $true
    
    # Check for roles array
    if ($meResponse.roles -and $meResponse.roles.Count -gt 0) {
        Add-TestResult -TestName "User has roles assigned" -Passed $true
        Write-Info "Roles: $($meResponse.roles.name -join ', ')"
    }
    else {
        Add-TestResult -TestName "User has roles assigned" -Passed $false -Details "No roles found"
    }
    
    # Check for permissions array
    if ($meResponse.permissions -and $meResponse.permissions.Count -gt 0) {
        Add-TestResult -TestName "User has permissions" -Passed $true
        Write-Info "Permission count: $($meResponse.permissions.Count)"
    }
    else {
        Add-TestResult -TestName "User has permissions" -Passed $false -Details "No permissions found"
    }
}
else {
    Add-TestResult -TestName "GET /auth/me" -Passed $false -Details "No response"
}

# ========================================
# 3. User Management Endpoints
# ========================================
Write-Section "3. User Management (requires users.view)"

$usersResponse = Invoke-AuthenticatedRequest -Method GET -Endpoint "/admin/users"
if ($usersResponse) {
    Add-TestResult -TestName "GET /admin/users" -Passed $true
    
    if ($usersResponse.data -or $usersResponse -is [array]) {
        $userCount = if ($usersResponse.data) { $usersResponse.data.Count } else { $usersResponse.Count }
        Write-Info "Users found: $userCount"
    }
}
else {
    Add-TestResult -TestName "GET /admin/users" -Passed $false -Details "No response"
}

# ========================================
# 4. Role Management Endpoints
# ========================================
Write-Section "4. Role Management (requires roles.view)"

$rolesResponse = Invoke-AuthenticatedRequest -Method GET -Endpoint "/admin/roles"
if ($rolesResponse) {
    Add-TestResult -TestName "GET /admin/roles" -Passed $true
    
    $roles = if ($rolesResponse.data) { $rolesResponse.data } else { $rolesResponse }
    if ($roles -is [array]) {
        Write-Info "Roles found: $($roles.Count)"
        foreach ($role in $roles) {
            Write-Info "  - $($role.name): $($role.display_name)"
        }
    }
}
else {
    Add-TestResult -TestName "GET /admin/roles" -Passed $false -Details "No response"
}

# ========================================
# 5. Permission List Endpoint
# ========================================
Write-Section "5. Permission List"

$permissionsResponse = Invoke-AuthenticatedRequest -Method GET -Endpoint "/admin/permissions"
if ($permissionsResponse) {
    Add-TestResult -TestName "GET /admin/permissions" -Passed $true
    
    $permissions = if ($permissionsResponse.data) { $permissionsResponse.data } else { $permissionsResponse }
    if ($permissions -is [array]) {
        Write-Info "Permission groups found: $($permissions.Count)"
        foreach ($group in $permissions) {
            if ($group.module -and $group.permissions) {
                Write-Info "  - $($group.module): $($group.permissions.Count) permissions"
            }
        }
    }
}
else {
    Add-TestResult -TestName "GET /admin/permissions" -Passed $false -Details "No response"
}

# ========================================
# 6. Activity Log Endpoints  
# ========================================
Write-Section "6. Activity Logs (requires activity.view)"

$activityResponse = Invoke-AuthenticatedRequest -Method GET -Endpoint "/admin/activity-logs?limit=10"
if ($activityResponse) {
    Add-TestResult -TestName "GET /admin/activity-logs" -Passed $true
    
    $logs = if ($activityResponse.data) { $activityResponse.data } else { $activityResponse }
    if ($logs -is [array]) {
        Write-Info "Recent activity logs: $($logs.Count)"
    }
}
else {
    Add-TestResult -TestName "GET /admin/activity-logs" -Passed $false -Details "No response"
}

# Activity stats
$statsResponse = Invoke-AuthenticatedRequest -Method GET -Endpoint "/admin/activity-logs/stats"
if ($statsResponse) {
    Add-TestResult -TestName "GET /admin/activity-logs/stats" -Passed $true
    
    if ($statsResponse.total_logs -ne $null) {
        Write-Info "Total logs: $($statsResponse.total_logs)"
        Write-Info "Today's logs: $($statsResponse.today_logs)"
    }
}
else {
    Add-TestResult -TestName "GET /admin/activity-logs/stats" -Passed $false -Details "No response"
}

# ========================================
# 7. Settings Endpoints
# ========================================
Write-Section "7. Settings Endpoints"

$settingsResponse = Invoke-AuthenticatedRequest -Method GET -Endpoint "/admin/settings"
if ($settingsResponse) {
    Add-TestResult -TestName "GET /admin/settings" -Passed $true
}
else {
    Add-TestResult -TestName "GET /admin/settings" -Passed $false -Details "No response or not implemented"
}

# ========================================
# 8. Verify Expected Role Types
# ========================================
Write-Section "8. Verify Role Types Exist"

$expectedRoles = @(
    "SUPER_ADMIN",
    "MANAGER",
    "STAFF_ORDERS",
    "STAFF_PRODUCTS",
    "ACCOUNTANT",
    "FULFILLMENT_STAFF",
    "SALES_AGENT",
    "CONTENT_MANAGER",
    "MARKETING"
)

if ($rolesResponse) {
    $rolesList = if ($rolesResponse.data) { $rolesResponse.data } else { $rolesResponse }
    $existingRoleNames = $rolesList | ForEach-Object { $_.name }
    
    foreach ($expectedRole in $expectedRoles) {
        if ($existingRoleNames -contains $expectedRole) {
            Add-TestResult -TestName "Role exists: $expectedRole" -Passed $true
        }
        else {
            Add-TestResult -TestName "Role exists: $expectedRole" -Passed $false -Details "Role not found"
        }
    }
}

# ========================================
# 9. Verify Permission Modules
# ========================================
Write-Section "9. Verify Permission Modules"

$expectedModules = @(
    "products",
    "orders",
    "customers",
    "inventory",
    "discounts",
    "analytics",
    "users",
    "roles",
    "activity"
)

if ($permissionsResponse) {
    $permsList = if ($permissionsResponse.data) { $permissionsResponse.data } else { $permissionsResponse }
    $existingModules = $permsList | ForEach-Object { $_.module } | Select-Object -Unique
    
    foreach ($expectedModule in $expectedModules) {
        if ($existingModules -contains $expectedModule) {
            Add-TestResult -TestName "Permission module: $expectedModule" -Passed $true
        }
        else {
            Add-TestResult -TestName "Permission module: $expectedModule" -Passed $false -Details "Module not found"
        }
    }
}

# ========================================
# Test Summary
# ========================================
Write-Section "TEST SUMMARY"

$totalTests = $script:Results.Passed + $script:Results.Failed
$passRate = if ($totalTests -gt 0) { [math]::Round(($script:Results.Passed / $totalTests) * 100, 1) } else { 0 }

Write-Host ""
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $($script:Results.Passed)" -ForegroundColor Green
Write-Host "Failed: $($script:Results.Failed)" -ForegroundColor Red
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 50) { "Yellow" } else { "Red" })
Write-Host ""

if ($script:Results.Failed -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($test in $script:Results.Tests | Where-Object { -not $_.Passed }) {
        Write-Host "  - $($test.Name): $($test.Details)" -ForegroundColor Red
    }
}

Write-Host "`nTest completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# Return exit code based on test results
if ($script:Results.Failed -eq 0) {
    Write-Host "`nAll RBAC tests passed successfully!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nSome RBAC tests failed. Please review the output above." -ForegroundColor Yellow
    exit 1
}
