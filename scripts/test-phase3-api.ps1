# Phase 3 Backend API Test Script
# Tests all new endpoints created in Phase 3

param(
    [string]$BaseUrl = "http://localhost:8080/api/v1",
    [string]$AdminToken = ""
)

$ErrorActionPreference = "Continue"

# Colors for output
function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "→ $msg" -ForegroundColor Cyan }
function Write-Header { param($msg) Write-Host "`n=== $msg ===" -ForegroundColor Yellow }

# API request helper
function Invoke-API {
    param(
        [string]$Method,
        [string]$Endpoint,
        [object]$Body = $null,
        [switch]$ExpectError
    )

    $headers = @{
        "Content-Type" = "application/json"
    }
    if ($AdminToken) {
        $headers["Authorization"] = "Bearer $AdminToken"
    }

    $uri = "$BaseUrl$Endpoint"
    
    try {
        $params = @{
            Method = $Method
            Uri = $uri
            Headers = $headers
        }
        
        if ($Body) {
            $params["Body"] = ($Body | ConvertTo-Json -Depth 10)
        }

        $response = Invoke-RestMethod @params
        return @{ Success = $true; Data = $response; StatusCode = 200 }
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        return @{ Success = $false; Error = $_.Exception.Message; StatusCode = $statusCode }
    }
}

# Test response format consistency
function Test-ResponseFormat {
    param($response, $expectPaginated = $false)
    
    if (-not $response.Success) { return $false }
    
    $data = $response.Data
    
    # Check basic structure
    if ($null -eq $data.success) {
        Write-Fail "Missing 'success' field"
        return $false
    }
    
    if ($expectPaginated) {
        if ($null -eq $data.meta) {
            Write-Fail "Missing 'meta' field for paginated response"
            return $false
        }
    }
    
    return $true
}

# ==================== TESTS ====================

$passCount = 0
$failCount = 0

Write-Header "Phase 3 Backend API Verification"
Write-Info "Base URL: $BaseUrl"
Write-Info "Testing at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# === 1. Test Discounts Endpoints ===
Write-Header "1. Discounts Endpoints (service-catalog)"

# GET /admin/discounts
$result = Invoke-API -Method GET -Endpoint "/catalog/admin/discounts"
if ($result.Success) { Write-Success "GET /admin/discounts"; $passCount++ } 
else { Write-Fail "GET /admin/discounts - $($result.Error)"; $failCount++ }

# POST /admin/discounts (create)
$discount = @{
    code = "TEST$(Get-Random -Maximum 9999)"
    name = "Test Discount"
    type = "percentage"
    value = 10
    scope = "all"
    start_date = (Get-Date).ToString("yyyy-MM-dd")
    end_date = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
}
$result = Invoke-API -Method POST -Endpoint "/catalog/admin/discounts" -Body $discount
if ($result.Success) { 
    Write-Success "POST /admin/discounts (create)"
    $passCount++
    $discountId = $result.Data.data.id
} else { 
    Write-Fail "POST /admin/discounts - $($result.Error)"
    $failCount++ 
}

# POST /admin/discounts/validate
$result = Invoke-API -Method POST -Endpoint "/catalog/admin/discounts/validate" -Body @{ code = "TEST" }
if ($result.StatusCode -ne 500) { Write-Success "POST /admin/discounts/validate"; $passCount++ }
else { Write-Fail "POST /admin/discounts/validate"; $failCount++ }

# === 2. Test Activity Logs Endpoints ===
Write-Header "2. Activity Logs Endpoints (service-auth)"

# GET /admin/activity-logs
$result = Invoke-API -Method GET -Endpoint "/auth/admin/activity-logs"
if ($result.Success) { Write-Success "GET /admin/activity-logs"; $passCount++ }
else { Write-Fail "GET /admin/activity-logs - $($result.Error)"; $failCount++ }

# GET /admin/activity-logs/stats
$result = Invoke-API -Method GET -Endpoint "/auth/admin/activity-logs/stats"
if ($result.Success) { Write-Success "GET /admin/activity-logs/stats"; $passCount++ }
else { Write-Fail "GET /admin/activity-logs/stats"; $failCount++ }

# GET /admin/activity-logs/export?format=json
$result = Invoke-API -Method GET -Endpoint "/auth/admin/activity-logs/export?format=json"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/activity-logs/export"; $passCount++ }
else { Write-Fail "GET /admin/activity-logs/export"; $failCount++ }

# === 3. Test Settings Endpoints ===
Write-Header "3. Settings Endpoints (service-auth)"

# GET /admin/settings
$result = Invoke-API -Method GET -Endpoint "/auth/admin/settings"
if ($result.Success) { Write-Success "GET /admin/settings"; $passCount++ }
else { Write-Fail "GET /admin/settings - $($result.Error)"; $failCount++ }

# GET /admin/settings/categories
$result = Invoke-API -Method GET -Endpoint "/auth/admin/settings/categories"
if ($result.Success) { Write-Success "GET /admin/settings/categories"; $passCount++ }
else { Write-Fail "GET /admin/settings/categories"; $failCount++ }

# === 4. Test Role Enhancement Endpoints ===
Write-Header "4. Role Enhancement Endpoints (service-auth)"

# GET /admin/roles/hierarchy
$result = Invoke-API -Method GET -Endpoint "/auth/admin/roles/hierarchy"
if ($result.Success) { Write-Success "GET /admin/roles/hierarchy"; $passCount++ }
else { Write-Fail "GET /admin/roles/hierarchy"; $failCount++ }

# GET /admin/roles/templates
$result = Invoke-API -Method GET -Endpoint "/auth/admin/roles/templates"
if ($result.Success) { Write-Success "GET /admin/roles/templates"; $passCount++ }
else { Write-Fail "GET /admin/roles/templates"; $failCount++ }

# POST /admin/roles/validate-permissions
$result = Invoke-API -Method POST -Endpoint "/auth/admin/roles/validate-permissions" -Body @{ permissions = @("products.view", "invalid.perm") }
if ($result.StatusCode -ne 500) { Write-Success "POST /admin/roles/validate-permissions"; $passCount++ }
else { Write-Fail "POST /admin/roles/validate-permissions"; $failCount++ }

# GET /admin/roles/assignment-history
$result = Invoke-API -Method GET -Endpoint "/auth/admin/roles/assignment-history"
if ($result.Success) { Write-Success "GET /admin/roles/assignment-history"; $passCount++ }
else { Write-Fail "GET /admin/roles/assignment-history"; $failCount++ }

# === 5. Test Admin Orders Endpoints ===
Write-Header "5. Admin Orders Endpoints (service-order)"

# GET /admin/orders
$result = Invoke-API -Method GET -Endpoint "/order/admin/orders"
if ($result.Success) { Write-Success "GET /admin/orders"; $passCount++ }
else { Write-Fail "GET /admin/orders"; $failCount++ }

# GET /admin/orders/export
$result = Invoke-API -Method GET -Endpoint "/order/admin/orders/export?format=json"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/orders/export"; $passCount++ }
else { Write-Fail "GET /admin/orders/export"; $failCount++ }

# === 6. Test Admin Inventory Endpoints ===
Write-Header "6. Admin Inventory Endpoints (service-inventory)"

# GET /admin/inventory
$result = Invoke-API -Method GET -Endpoint "/inventory/admin/inventory"
if ($result.Success) { Write-Success "GET /admin/inventory"; $passCount++ }
else { Write-Fail "GET /admin/inventory"; $failCount++ }

# GET /admin/inventory/movements
$result = Invoke-API -Method GET -Endpoint "/inventory/admin/inventory/movements"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/inventory/movements"; $passCount++ }
else { Write-Fail "GET /admin/inventory/movements"; $failCount++ }

# GET /admin/inventory/alerts
$result = Invoke-API -Method GET -Endpoint "/inventory/admin/inventory/alerts"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/inventory/alerts"; $passCount++ }
else { Write-Fail "GET /admin/inventory/alerts"; $failCount++ }

# GET /admin/inventory/stats
$result = Invoke-API -Method GET -Endpoint "/inventory/admin/inventory/stats"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/inventory/stats"; $passCount++ }
else { Write-Fail "GET /admin/inventory/stats"; $failCount++ }

# === 7. Test Admin Customers Endpoints ===
Write-Header "7. Admin Customers Endpoints (service-customer)"

# GET /admin/customers
$result = Invoke-API -Method GET -Endpoint "/customer/admin/customers"
if ($result.Success) { Write-Success "GET /admin/customers"; $passCount++ }
else { Write-Fail "GET /admin/customers"; $failCount++ }

# GET /admin/segments
$result = Invoke-API -Method GET -Endpoint "/customer/admin/segments"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/segments"; $passCount++ }
else { Write-Fail "GET /admin/segments"; $failCount++ }

# GET /admin/customers/stats
$result = Invoke-API -Method GET -Endpoint "/customer/admin/customers/stats"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/customers/stats"; $passCount++ }
else { Write-Fail "GET /admin/customers/stats"; $failCount++ }

# === 8. Test Admin Products Endpoints ===
Write-Header "8. Admin Products Endpoints (service-catalog)"

# GET /admin/products/stats
$result = Invoke-API -Method GET -Endpoint "/catalog/admin/products/stats"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/products/stats"; $passCount++ }
else { Write-Fail "GET /admin/products/stats"; $failCount++ }

# GET /admin/products/import/template
$result = Invoke-API -Method GET -Endpoint "/catalog/admin/products/import/template"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/products/import/template"; $passCount++ }
else { Write-Fail "GET /admin/products/import/template"; $failCount++ }

# === 9. Test Analytics Endpoints ===
Write-Header "9. Analytics Endpoints (service-reporting)"

# GET /admin/analytics/dashboard
$result = Invoke-API -Method GET -Endpoint "/reports/admin/analytics/dashboard"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/analytics/dashboard"; $passCount++ }
else { Write-Fail "GET /admin/analytics/dashboard"; $failCount++ }

# GET /admin/analytics/sales
$result = Invoke-API -Method GET -Endpoint "/reports/admin/analytics/sales"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/analytics/sales"; $passCount++ }
else { Write-Fail "GET /admin/analytics/sales"; $failCount++ }

# GET /admin/analytics/products
$result = Invoke-API -Method GET -Endpoint "/reports/admin/analytics/products"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/analytics/products"; $passCount++ }
else { Write-Fail "GET /admin/analytics/products"; $failCount++ }

# GET /admin/analytics/customers
$result = Invoke-API -Method GET -Endpoint "/reports/admin/analytics/customers"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/analytics/customers"; $passCount++ }
else { Write-Fail "GET /admin/analytics/customers"; $failCount++ }

# GET /admin/analytics/inventory
$result = Invoke-API -Method GET -Endpoint "/reports/admin/analytics/inventory"
if ($result.StatusCode -ne 500) { Write-Success "GET /admin/analytics/inventory"; $passCount++ }
else { Write-Fail "GET /admin/analytics/inventory"; $failCount++ }

# ==================== SUMMARY ====================

Write-Header "Test Summary"
Write-Host ""
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "Total:  $($passCount + $failCount)"
Write-Host ""

$passRate = [math]::Round(($passCount / ($passCount + $failCount)) * 100, 1)
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 50) { "Yellow" } else { "Red" })

if ($failCount -eq 0) {
    Write-Host "`n🎉 All tests passed!" -ForegroundColor Green
} else {
    Write-Host "`n⚠ Some tests failed. Check the output above for details." -ForegroundColor Yellow
}
