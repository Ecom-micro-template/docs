# Phase 6: Comprehensive API Test Script
# Tests all microservice endpoints against Docker local environment
# Usage: .\test-phase6-api.ps1 -ApiBaseUrl "http://localhost" -AdminEmail "admin@kilangdesamurnibatik.com"

param(
    [string]$ApiBaseUrl = "http://localhost",
    [string]$AdminEmail = "admin@kilangdesamurnibatik.com",
    [string]$AdminPassword = "Admin123!@#"
)

$ErrorActionPreference = "Continue"

# Service ports mapping
$Services = @{
    Auth = 8001
    Catalog = 8002
    Inventory = 8003
    Order = 8004
    Customer = 8005
    Agent = 8006
    Notification = 8007
    Reporting = 8008
}

# Color output functions
function Write-Success { param($msg) Write-Host "[PASS] $msg" -ForegroundColor Green }
function Write-Failure { param($msg) Write-Host "[FAIL] $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Section { param($msg) Write-Host "`n==================== $msg ====================" -ForegroundColor Yellow }
function Write-SubSection { param($msg) Write-Host "`n--- $msg ---" -ForegroundColor Magenta }

# Global variables
$script:AuthToken = ""
$script:RefreshToken = ""
$script:Results = @{ Passed = 0; Failed = 0; Skipped = 0; Tests = @() }

# Test result tracking
function Add-TestResult {
    param([string]$Service, [string]$Endpoint, [string]$Method, [bool]$Passed, [string]$Details = "", [int]$StatusCode = 0)
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    if ($Passed) { $script:Results.Passed++ } else { $script:Results.Failed++ }
    
    $script:Results.Tests += @{
        Service = $Service
        Endpoint = $Endpoint
        Method = $Method
        Status = $status
        Details = $Details
        StatusCode = $StatusCode
    }
    
    $icon = if ($Passed) { "[OK]" } else { "[X]" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "  $icon [$Method] $Endpoint $(if($StatusCode){"($StatusCode)"}) $(if($Details){": $Details"})" -ForegroundColor $color
}

# HTTP request helper
function Invoke-ApiRequest {
    param(
        [string]$Service,
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [switch]$RequireAuth,
        [int[]]$ExpectedStatus = @(200, 201),
        [switch]$ReturnRaw
    )
    
    $port = $Services[$Service]
    $uri = "$ApiBaseUrl`:$port/api/v1$Endpoint"
    
    $headers = @{ "Content-Type" = "application/json" }
    if ($RequireAuth -and $script:AuthToken) {
        $headers["Authorization"] = "Bearer $script:AuthToken"
    }
    
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
        
        $response = Invoke-WebRequest @params
        $statusCode = $response.StatusCode
        
        if ($ExpectedStatus -contains $statusCode) {
            if ($ReturnRaw) { return $response }
            return @{ Success = $true; Data = ($response.Content | ConvertFrom-Json); StatusCode = $statusCode }
        } else {
            return @{ Success = $false; Data = $null; StatusCode = $statusCode; Error = "Unexpected status" }
        }
    }
    catch {
        $statusCode = 0
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
        return @{ Success = $false; Data = $null; StatusCode = $statusCode; Error = $_.Exception.Message }
    }
}

# ============================================================================
# MAIN TEST EXECUTION
# ============================================================================

Write-Section "Phase 6: Comprehensive API Testing"
Write-Info "API Base URL: $ApiBaseUrl"
Write-Info "Test Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info ""

# ============================================================================
# 1. SERVICE HEALTH CHECKS
# ============================================================================
Write-Section "1. Service Health Checks"

foreach ($svc in $Services.GetEnumerator()) {
    $healthUri = "$ApiBaseUrl`:$($svc.Value)/health"
    try {
        $response = Invoke-WebRequest -Uri $healthUri -Method GET -TimeoutSec 5 -ErrorAction Stop
        Add-TestResult -Service $svc.Key -Endpoint "/health" -Method "GET" -Passed $true -StatusCode $response.StatusCode
    }
    catch {
        # Try alternative health endpoint
        try {
            $altUri = "$ApiBaseUrl`:$($svc.Value)/api/v1/health"
            $response = Invoke-WebRequest -Uri $altUri -Method GET -TimeoutSec 5 -ErrorAction Stop
            Add-TestResult -Service $svc.Key -Endpoint "/api/v1/health" -Method "GET" -Passed $true -StatusCode $response.StatusCode
        }
        catch {
            Add-TestResult -Service $svc.Key -Endpoint "/health" -Method "GET" -Passed $false -Details "Service unreachable"
        }
    }
}

# ============================================================================
# 2. AUTHENTICATION TESTS
# ============================================================================
Write-Section "2. Authentication Service (Auth)"

Write-SubSection "Login Flow"

# Test admin login
$loginBody = @{ email = $AdminEmail; password = $AdminPassword }
$loginResult = Invoke-ApiRequest -Service "Auth" -Method "POST" -Endpoint "/auth/login" -Body $loginBody

if ($loginResult.Success -and ($loginResult.Data.token -or $loginResult.Data.data.token)) {
    $script:AuthToken = if ($loginResult.Data.token) { $loginResult.Data.token } else { $loginResult.Data.data.token }
    if ($loginResult.Data.refresh_token) { $script:RefreshToken = $loginResult.Data.refresh_token }
    Add-TestResult -Service "Auth" -Endpoint "/auth/login" -Method "POST" -Passed $true -Details "Token obtained" -StatusCode $loginResult.StatusCode
} else {
    Add-TestResult -Service "Auth" -Endpoint "/auth/login" -Method "POST" -Passed $false -Details $loginResult.Error -StatusCode $loginResult.StatusCode
    Write-Failure "Cannot continue without authentication token"
    exit 1
}

Write-SubSection "Current User"

# Test /auth/me
$meResult = Invoke-ApiRequest -Service "Auth" -Method "GET" -Endpoint "/auth/me" -RequireAuth
if ($meResult.Success) {
    $userData = if ($meResult.Data.data) { $meResult.Data.data } else { $meResult.Data }
    Add-TestResult -Service "Auth" -Endpoint "/auth/me" -Method "GET" -Passed $true -StatusCode $meResult.StatusCode
    
    # Check roles
    if ($userData.roles -and $userData.roles.Count -gt 0) {
        Add-TestResult -Service "Auth" -Endpoint "/auth/me (roles)" -Method "GET" -Passed $true -Details "Roles: $($userData.roles.Count)"
    }
    
    # Check permissions
    if ($userData.permissions -and $userData.permissions.Count -gt 0) {
        Add-TestResult -Service "Auth" -Endpoint "/auth/me (permissions)" -Method "GET" -Passed $true -Details "Permissions: $($userData.permissions.Count)"
    }
} else {
    Add-TestResult -Service "Auth" -Endpoint "/auth/me" -Method "GET" -Passed $false -Details $meResult.Error -StatusCode $meResult.StatusCode
}

Write-SubSection "User Management"

# Test list users
$usersResult = Invoke-ApiRequest -Service "Auth" -Method "GET" -Endpoint "/admin/users" -RequireAuth
Add-TestResult -Service "Auth" -Endpoint "/admin/users" -Method "GET" -Passed $usersResult.Success -StatusCode $usersResult.StatusCode

# Test list roles
$rolesResult = Invoke-ApiRequest -Service "Auth" -Method "GET" -Endpoint "/admin/roles" -RequireAuth
Add-TestResult -Service "Auth" -Endpoint "/admin/roles" -Method "GET" -Passed $rolesResult.Success -StatusCode $rolesResult.StatusCode

# Test list permissions
$permsResult = Invoke-ApiRequest -Service "Auth" -Method "GET" -Endpoint "/admin/permissions" -RequireAuth
Add-TestResult -Service "Auth" -Endpoint "/admin/permissions" -Method "GET" -Passed $permsResult.Success -StatusCode $permsResult.StatusCode

Write-SubSection "Activity Logs"

$activityResult = Invoke-ApiRequest -Service "Auth" -Method "GET" -Endpoint "/admin/activity-logs?limit=5" -RequireAuth
Add-TestResult -Service "Auth" -Endpoint "/admin/activity-logs" -Method "GET" -Passed $activityResult.Success -StatusCode $activityResult.StatusCode

# ============================================================================
# 3. CATALOG SERVICE TESTS
# ============================================================================
Write-Section "3. Catalog Service"

Write-SubSection "Public Endpoints"

# Test list products (public)
$productsResult = Invoke-ApiRequest -Service "Catalog" -Method "GET" -Endpoint "/products"
Add-TestResult -Service "Catalog" -Endpoint "/products" -Method "GET" -Passed $productsResult.Success -StatusCode $productsResult.StatusCode

# Test list categories (public)
$categoriesResult = Invoke-ApiRequest -Service "Catalog" -Method "GET" -Endpoint "/categories"
Add-TestResult -Service "Catalog" -Endpoint "/categories" -Method "GET" -Passed $categoriesResult.Success -StatusCode $categoriesResult.StatusCode

Write-SubSection "Admin Endpoints"

# Test admin products list
$adminProductsResult = Invoke-ApiRequest -Service "Catalog" -Method "GET" -Endpoint "/admin/products" -RequireAuth
Add-TestResult -Service "Catalog" -Endpoint "/admin/products" -Method "GET" -Passed $adminProductsResult.Success -StatusCode $adminProductsResult.StatusCode

# Test admin categories list
$adminCategoriesResult = Invoke-ApiRequest -Service "Catalog" -Method "GET" -Endpoint "/admin/categories" -RequireAuth
Add-TestResult -Service "Catalog" -Endpoint "/admin/categories" -Method "GET" -Passed $adminCategoriesResult.Success -StatusCode $adminCategoriesResult.StatusCode

# Test discounts list
$discountsResult = Invoke-ApiRequest -Service "Catalog" -Method "GET" -Endpoint "/admin/discounts" -RequireAuth
Add-TestResult -Service "Catalog" -Endpoint "/admin/discounts" -Method "GET" -Passed $discountsResult.Success -StatusCode $discountsResult.StatusCode

# ============================================================================
# 4. ORDER SERVICE TESTS
# ============================================================================
Write-Section "4. Order Service"

# Test admin orders list
$ordersResult = Invoke-ApiRequest -Service "Order" -Method "GET" -Endpoint "/admin/orders" -RequireAuth
Add-TestResult -Service "Order" -Endpoint "/admin/orders" -Method "GET" -Passed $ordersResult.Success -StatusCode $ordersResult.StatusCode

# Test user orders (my orders)
$myOrdersResult = Invoke-ApiRequest -Service "Order" -Method "GET" -Endpoint "/orders/my" -RequireAuth
Add-TestResult -Service "Order" -Endpoint "/orders/my" -Method "GET" -Passed $myOrdersResult.Success -StatusCode $myOrdersResult.StatusCode

# ============================================================================
# 5. INVENTORY SERVICE TESTS
# ============================================================================
Write-Section "5. Inventory Service"

# Test inventory list
$inventoryResult = Invoke-ApiRequest -Service "Inventory" -Method "GET" -Endpoint "/admin/inventory" -RequireAuth
Add-TestResult -Service "Inventory" -Endpoint "/admin/inventory" -Method "GET" -Passed $inventoryResult.Success -StatusCode $inventoryResult.StatusCode

# Test warehouses list
$warehousesResult = Invoke-ApiRequest -Service "Inventory" -Method "GET" -Endpoint "/admin/warehouses" -RequireAuth
Add-TestResult -Service "Inventory" -Endpoint "/admin/warehouses" -Method "GET" -Passed $warehousesResult.Success -StatusCode $warehousesResult.StatusCode

# Test low stock
$lowStockResult = Invoke-ApiRequest -Service "Inventory" -Method "GET" -Endpoint "/admin/inventory/low-stock" -RequireAuth
Add-TestResult -Service "Inventory" -Endpoint "/admin/inventory/low-stock" -Method "GET" -Passed $lowStockResult.Success -StatusCode $lowStockResult.StatusCode

# ============================================================================
# 6. CUSTOMER SERVICE TESTS
# ============================================================================
Write-Section "6. Customer Service"

# Test admin customers list
$customersResult = Invoke-ApiRequest -Service "Customer" -Method "GET" -Endpoint "/admin/customers" -RequireAuth
Add-TestResult -Service "Customer" -Endpoint "/admin/customers" -Method "GET" -Passed $customersResult.Success -StatusCode $customersResult.StatusCode

# Test customer profile
$profileResult = Invoke-ApiRequest -Service "Customer" -Method "GET" -Endpoint "/customers/me" -RequireAuth
Add-TestResult -Service "Customer" -Endpoint "/customers/me" -Method "GET" -Passed $profileResult.Success -StatusCode $profileResult.StatusCode

# ============================================================================
# 7. REPORTING SERVICE TESTS
# ============================================================================
Write-Section "7. Reporting Service"

# Test sales trends
$trendsResult = Invoke-ApiRequest -Service "Reporting" -Method "GET" -Endpoint "/reports/sales/trends" -RequireAuth
Add-TestResult -Service "Reporting" -Endpoint "/reports/sales/trends" -Method "GET" -Passed $trendsResult.Success -StatusCode $trendsResult.StatusCode

# Test sales overview
$overviewResult = Invoke-ApiRequest -Service "Reporting" -Method "GET" -Endpoint "/reports/sales/overview" -RequireAuth
Add-TestResult -Service "Reporting" -Endpoint "/reports/sales/overview" -Method "GET" -Passed $overviewResult.Success -StatusCode $overviewResult.StatusCode

# Test top products
$topProductsResult = Invoke-ApiRequest -Service "Reporting" -Method "GET" -Endpoint "/reports/sales/top-products" -RequireAuth
Add-TestResult -Service "Reporting" -Endpoint "/reports/sales/top-products" -Method "GET" -Passed $topProductsResult.Success -StatusCode $topProductsResult.StatusCode

# Test order status breakdown
$statusBreakdownResult = Invoke-ApiRequest -Service "Reporting" -Method "GET" -Endpoint "/reports/orders/status-breakdown" -RequireAuth
Add-TestResult -Service "Reporting" -Endpoint "/reports/orders/status-breakdown" -Method "GET" -Passed $statusBreakdownResult.Success -StatusCode $statusBreakdownResult.StatusCode

# ============================================================================
# 8. RBAC PERMISSION TESTS
# ============================================================================
Write-Section "8. RBAC Permission Verification"

# Verify expected roles exist
if ($rolesResult.Success) {
    $rolesList = if ($rolesResult.Data.data) { $rolesResult.Data.data } else { $rolesResult.Data }
    $expectedRoles = @("SUPER_ADMIN", "MANAGER", "STAFF_ORDERS", "STAFF_PRODUCTS", "ACCOUNTANT", "MARKETING")
    
    foreach ($role in $expectedRoles) {
        $found = $rolesList | Where-Object { $_.name -eq $role }
        Add-TestResult -Service "RBAC" -Endpoint "Role: $role" -Method "CHECK" -Passed ($null -ne $found)
    }
}

# Verify permission enforcement (check that requests without auth get 401)
Write-SubSection "Unauthenticated Access Denial"

$unauthTests = @(
    @{ Service = "Auth"; Endpoint = "/admin/users" },
    @{ Service = "Catalog"; Endpoint = "/admin/products" },
    @{ Service = "Inventory"; Endpoint = "/admin/inventory" }
)

foreach ($test in $unauthTests) {
    try {
        $port = $Services[$test.Service]
        $uri = "$ApiBaseUrl`:$port/api/v1$($test.Endpoint)"
        $response = Invoke-WebRequest -Uri $uri -Method GET -ErrorAction Stop
        Add-TestResult -Service "RBAC" -Endpoint "$($test.Endpoint) (unauth)" -Method "GET" -Passed $false -Details "Should return 401"
    }
    catch {
        $statusCode = [int]$_.Exception.Response.StatusCode
        $passed = ($statusCode -eq 401)
        Add-TestResult -Service "RBAC" -Endpoint "$($test.Endpoint) (unauth)" -Method "GET" -Passed $passed -Details "Got $statusCode" -StatusCode $statusCode
    }
}

# ============================================================================
# TEST SUMMARY
# ============================================================================
Write-Section "TEST SUMMARY"

$totalTests = $script:Results.Passed + $script:Results.Failed
$passRate = if ($totalTests -gt 0) { [math]::Round(($script:Results.Passed / $totalTests) * 100, 1) } else { 0 }

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor White
Write-Host "  Total Tests:  $totalTests" -ForegroundColor White
Write-Host "  Passed:       $($script:Results.Passed)" -ForegroundColor Green
Write-Host "  Failed:       $($script:Results.Failed)" -ForegroundColor $(if ($script:Results.Failed -gt 0) { "Red" } else { "Green" })
Write-Host "  Pass Rate:    $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 50) { "Yellow" } else { "Red" })
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor White
Write-Host ""

# Failed tests summary
if ($script:Results.Failed -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    foreach ($test in $script:Results.Tests | Where-Object { $_.Status -eq "FAIL" }) {
        Write-Host "  [X] [$($test.Service)] $($test.Method) $($test.Endpoint): $($test.Details)" -ForegroundColor Red
    }
    Write-Host ""
}

# Service summary
Write-Host "Results by Service:" -ForegroundColor Cyan
$script:Results.Tests | Group-Object Service | ForEach-Object {
    $passed = ($_.Group | Where-Object { $_.Status -eq "PASS" }).Count
    $total = $_.Group.Count
    $color = if ($passed -eq $total) { "Green" } elseif ($passed -gt 0) { "Yellow" } else { "Red" }
    Write-Host "  $($_.Name): $passed/$total passed" -ForegroundColor $color
}

Write-Host ""
Write-Host "Test completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan

# Export results to JSON
$exportPath = Join-Path $PSScriptRoot "test-results-phase6.json"
$script:Results | ConvertTo-Json -Depth 5 | Out-File $exportPath -Encoding UTF8
Write-Info "Results exported to: $exportPath"

# Exit code
if ($script:Results.Failed -eq 0) {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nSome tests failed. Please review the output above." -ForegroundColor Yellow
    exit 1
}
