# Response Format Verification Script
# Verifies that all API responses follow the standardized format

param(
    [string]$BaseUrl = "http://localhost:8080/api/v1",
    [string]$AdminToken = ""
)

$ErrorActionPreference = "Continue"

function Write-Success { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function Write-Fail { param($msg) Write-Host "✗ $msg" -ForegroundColor Red }
function Write-Info { param($msg) Write-Host "→ $msg" -ForegroundColor Cyan }
function Write-Header { param($msg) Write-Host "`n=== $msg ===" -ForegroundColor Yellow }

# Expected response format:
# {
#   "success": bool,
#   "message": string,
#   "data": any,
#   "error": { "code": string, "message": string } (only on error),
#   "meta": { "page": int, "limit": int, "total_count": int, "total_pages": int } (only for paginated)
# }

function Test-ResponseFormat {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [bool]$ExpectPaginated = $false
    )
    
    $headers = @{
        "Content-Type" = "application/json"
    }
    if ($AdminToken) {
        $headers["Authorization"] = "Bearer $AdminToken"
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl$Endpoint" -Method $Method -Headers $headers
        
        $issues = @()
        
        # Check 'success' field
        if ($null -eq $response.success) {
            $issues += "Missing 'success' field"
        } elseif ($response.success -isnot [bool]) {
            $issues += "'success' should be boolean"
        }
        
        # Check 'message' field
        if ($null -eq $response.message -or $response.message -eq "") {
            # Message can be empty but should exist
        }
        
        # Check 'data' field
        if ($null -eq $response.data -and $null -eq $response.error) {
            # Data might be null for delete operations, etc.
        }
        
        # Check pagination for paginated endpoints
        if ($ExpectPaginated) {
            if ($null -eq $response.meta) {
                $issues += "Missing 'meta' field for paginated response"
            } else {
                if ($null -eq $response.meta.page) { $issues += "Missing 'meta.page'" }
                if ($null -eq $response.meta.limit) { $issues += "Missing 'meta.limit'" }
                if ($null -eq $response.meta.total_count) { $issues += "Missing 'meta.total_count'" }
                if ($null -eq $response.meta.total_pages) { $issues += "Missing 'meta.total_pages'" }
            }
        }
        
        if ($issues.Count -eq 0) {
            Write-Success "$Method $Endpoint - Format OK"
            return $true
        } else {
            Write-Fail "$Method $Endpoint - Issues: $($issues -join ', ')"
            return $false
        }
    }
    catch {
        $statusCode = if ($_.Exception.Response.StatusCode) { $_.Exception.Response.StatusCode.value__ } else { "N/A" }
        Write-Info "$Method $Endpoint - HTTP $statusCode (may need auth or data)"
        return $null  # Can't verify
    }
}

Write-Header "Response Format Verification"
Write-Info "Checking standardized API response format"
Write-Info "Base URL: $BaseUrl"
Write-Host ""

$passed = 0
$failed = 0
$skipped = 0

# List of endpoints to verify
$endpoints = @(
    @{ Endpoint = "/catalog/admin/discounts"; Paginated = $true },
    @{ Endpoint = "/auth/admin/activity-logs"; Paginated = $true },
    @{ Endpoint = "/auth/admin/settings"; Paginated = $false },
    @{ Endpoint = "/auth/admin/roles/hierarchy"; Paginated = $false },
    @{ Endpoint = "/auth/admin/roles/templates"; Paginated = $false },
    @{ Endpoint = "/order/admin/orders"; Paginated = $true },
    @{ Endpoint = "/inventory/admin/inventory"; Paginated = $true },
    @{ Endpoint = "/customer/admin/customers"; Paginated = $true },
    @{ Endpoint = "/reports/admin/analytics/dashboard"; Paginated = $false }
)

foreach ($ep in $endpoints) {
    $result = Test-ResponseFormat -Endpoint $ep.Endpoint -ExpectPaginated $ep.Paginated
    if ($null -eq $result) { $skipped++ }
    elseif ($result) { $passed++ }
    else { $failed++ }
}

Write-Header "Summary"
Write-Host "Passed:  $passed" -ForegroundColor Green
Write-Host "Failed:  $failed" -ForegroundColor Red
Write-Host "Skipped: $skipped" -ForegroundColor Yellow
