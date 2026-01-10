<#
.SYNOPSIS
    Tests ServiceNow connectivity for ESS integration
    
.DESCRIPTION
    Validates ServiceNow REST API connectivity using Basic or OAuth authentication.
    Tests incident creation, retrieval, and updates to ensure ESS can interact with ServiceNow.
    
.PARAMETER Instance
    ServiceNow instance name (e.g., "yourcompany" for yourcompany.service-now.com)
    
.PARAMETER Username
    ServiceNow username for Basic authentication
    
.PARAMETER Password
    ServiceNow password for Basic authentication
    
.PARAMETER OAuthToken
    OAuth access token (alternative to username/password)
    
.PARAMETER TestIncidentCreation
    Test creating a test incident (default: true)
    
.EXAMPLE
    .\Test-ServiceNowConnectivity.ps1 -Instance "contoso" -Username "admin" -Password "P@ssw0rd"
    
.EXAMPLE
    .\Test-ServiceNowConnectivity.ps1 -Instance "contoso" -OAuthToken "abc123..."
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Instance,
    
    [Parameter(Mandatory=$false)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$Password,
    
    [Parameter(Mandatory=$false)]
    [string]$OAuthToken,
    
    [Parameter(Mandatory=$false)]
    [bool]$TestIncidentCreation = $true
)

# Script configuration
$ApiVersion = "v2"
$TestResults = @()

function Write-TestStep {
    param(
        [string]$Message,
        [string]$Status = "Info"
    )
    
    $color = switch ($Status) {
        "Success" { "Green" }
        "Error" { "Red" }
        "Warning" { "Yellow" }
        default { "Cyan" }
    }
    
    $icon = switch ($Status) {
        "Success" { "✓" }
        "Error" { "✗" }
        "Warning" { "⚠" }
        default { "→" }
    }
    
    Write-Host "$icon $Message" -ForegroundColor $color
}

function Test-ServiceNowAPI {
    param(
        [string]$BaseUrl,
        [hashtable]$Headers,
        [string]$Endpoint,
        [string]$Method = "GET",
        [object]$Body = $null
    )
    
    $uri = "$BaseUrl/$Endpoint"
    
    try {
        $params = @{
            Uri = $uri
            Method = $Method
            Headers = $Headers
            ContentType = "application/json"
        }
        
        if ($Body) {
            $params.Body = ($Body | ConvertTo-Json -Depth 10)
        }
        
        $response = Invoke-RestMethod @params
        
        return @{
            Success = $true
            Data = $response
            StatusCode = 200
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            StatusCode = $_.Exception.Response.StatusCode.value__
        }
    }
}

# Main execution
Write-Host "`n╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║            ServiceNow Connectivity Test for ESS Integration          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Gather credentials if not provided
if (-not $Instance) {
    $Instance = Read-Host "ServiceNow Instance (e.g., 'contoso' for contoso.service-now.com)"
}

if (-not $OAuthToken) {
    if (-not $Username) {
        $Username = Read-Host "ServiceNow Username"
    }
    if (-not $Password) {
        $securePassword = Read-Host "ServiceNow Password" -AsSecureString
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    }
}

# Build base URL and headers
$baseUrl = "https://$Instance.service-now.com/api/now"

if ($OAuthToken) {
    $headers = @{
        "Authorization" = "Bearer $OAuthToken"
        "Accept" = "application/json"
    }
    Write-TestStep "Using OAuth authentication" -Status "Info"
}
else {
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Username):$($Password)"))
    $headers = @{
        "Authorization" = "Basic $base64Auth"
        "Accept" = "application/json"
    }
    Write-TestStep "Using Basic authentication with username: $Username" -Status "Info"
}

Write-Host ""

# Test 1: Connection Test
Write-TestStep "TEST 1: Testing basic connectivity to $Instance.service-now.com..." -Status "Info"
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    $testConnection = Test-Path "https://$Instance.service-now.com" -ErrorAction Stop
    $result = Test-ServiceNowAPI -BaseUrl $baseUrl -Headers $headers -Endpoint "table/sys_user?sysparm_limit=1"
    $stopwatch.Stop()
    
    if ($result.Success) {
        Write-TestStep "Connection successful! (Response time: $($stopwatch.ElapsedMilliseconds)ms)" -Status "Success"
        $TestResults += @{
            Test = "Connection Test"
            Status = "Passed"
            Duration = $stopwatch.ElapsedMilliseconds
            Message = "Successfully connected to ServiceNow instance"
        }
    }
    else {
        Write-TestStep "Connection failed: $($result.Error)" -Status "Error"
        $TestResults += @{
            Test = "Connection Test"
            Status = "Failed"
            Duration = $stopwatch.ElapsedMilliseconds
            Message = $result.Error
        }
        exit 1
    }
}
catch {
    $stopwatch.Stop()
    Write-TestStep "Connection failed: $($_.Exception.Message)" -Status "Error"
    $TestResults += @{
        Test = "Connection Test"
        Status = "Failed"
        Duration = $stopwatch.ElapsedMilliseconds
        Message = $_.Exception.Message
    }
    exit 1
}

Write-Host ""

# Test 2: Retrieve Current User
Write-TestStep "TEST 2: Retrieving current user information..." -Status "Info"
$stopwatch.Restart()

$result = Test-ServiceNowAPI -BaseUrl $baseUrl -Headers $headers -Endpoint "table/sys_user?sysparm_query=user_name=$Username&sysparm_limit=1"
$stopwatch.Stop()

if ($result.Success -and $result.Data.result) {
    $user = $result.Data.result[0]
    Write-TestStep "User found: $($user.name) ($($user.email))" -Status "Success"
    Write-TestStep "  User ID: $($user.sys_id)" -Status "Info"
    Write-TestStep "  Active: $($user.active)" -Status "Info"
    Write-TestStep "  Response time: $($stopwatch.ElapsedMilliseconds)ms" -Status "Info"
    
    $TestResults += @{
        Test = "User Retrieval"
        Status = "Passed"
        Duration = $stopwatch.ElapsedMilliseconds
        Message = "Retrieved user: $($user.name)"
    }
}
else {
    Write-TestStep "Failed to retrieve user information" -Status "Warning"
    $TestResults += @{
        Test = "User Retrieval"
        Status = "Warning"
        Duration = $stopwatch.ElapsedMilliseconds
        Message = "Could not retrieve user information"
    }
}

Write-Host ""

# Test 3: Query Incidents Table
Write-TestStep "TEST 3: Querying incidents table..." -Status "Info"
$stopwatch.Restart()

$result = Test-ServiceNowAPI -BaseUrl $baseUrl -Headers $headers -Endpoint "table/incident?sysparm_limit=5&sysparm_query=ORDERBYDESCsys_created_on"
$stopwatch.Stop()

if ($result.Success) {
    $incidentCount = $result.Data.result.Count
    Write-TestStep "Successfully queried incidents table" -Status "Success"
    Write-TestStep "  Found $incidentCount recent incidents" -Status "Info"
    Write-TestStep "  Response time: $($stopwatch.ElapsedMilliseconds)ms" -Status "Info"
    
    if ($incidentCount -gt 0) {
        $latestIncident = $result.Data.result[0]
        Write-TestStep "  Latest incident: $($latestIncident.number) - $($latestIncident.short_description)" -Status "Info"
    }
    
    $TestResults += @{
        Test = "Incident Query"
        Status = "Passed"
        Duration = $stopwatch.ElapsedMilliseconds
        Message = "Retrieved $incidentCount incidents"
    }
}
else {
    Write-TestStep "Failed to query incidents: $($result.Error)" -Status "Error"
    $TestResults += @{
        Test = "Incident Query"
        Status = "Failed"
        Duration = $stopwatch.ElapsedMilliseconds
        Message = $result.Error
    }
}

Write-Host ""

# Test 4: Create Test Incident (if enabled)
if ($TestIncidentCreation) {
    Write-TestStep "TEST 4: Creating test incident..." -Status "Info"
    $stopwatch.Restart()
    
    $testIncident = @{
        short_description = "ESS Connectivity Test - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        description = "This is an automated test incident created by the ESS Pre-flight Validator to verify ServiceNow integration. This incident can be safely closed or deleted."
        urgency = 3
        impact = 3
        category = "inquiry"
        caller_id = $Username
    }
    
    $result = Test-ServiceNowAPI -BaseUrl $baseUrl -Headers $headers -Endpoint "table/incident" -Method "POST" -Body $testIncident
    $stopwatch.Stop()
    
    if ($result.Success -and $result.Data.result) {
        $createdIncident = $result.Data.result
        Write-TestStep "Test incident created successfully!" -Status "Success"
        Write-TestStep "  Incident Number: $($createdIncident.number)" -Status "Info"
        Write-TestStep "  Incident Sys ID: $($createdIncident.sys_id)" -Status "Info"
        Write-TestStep "  Response time: $($stopwatch.ElapsedMilliseconds)ms" -Status "Info"
        
        $TestResults += @{
            Test = "Incident Creation"
            Status = "Passed"
            Duration = $stopwatch.ElapsedMilliseconds
            Message = "Created incident: $($createdIncident.number)"
        }
        
        # Test 5: Update the test incident
        Write-Host ""
        Write-TestStep "TEST 5: Updating test incident..." -Status "Info"
        $stopwatch.Restart()
        
        $updateData = @{
            work_notes = "ESS connectivity test completed successfully. This incident can be closed."
            state = 7  # Closed
        }
        
        $updateResult = Test-ServiceNowAPI -BaseUrl $baseUrl -Headers $headers -Endpoint "table/incident/$($createdIncident.sys_id)" -Method "PATCH" -Body $updateData
        $stopwatch.Stop()
        
        if ($updateResult.Success) {
            Write-TestStep "Test incident updated and closed successfully!" -Status "Success"
            Write-TestStep "  Response time: $($stopwatch.ElapsedMilliseconds)ms" -Status "Info"
            
            $TestResults += @{
                Test = "Incident Update"
                Status = "Passed"
                Duration = $stopwatch.ElapsedMilliseconds
                Message = "Updated incident: $($createdIncident.number)"
            }
        }
        else {
            Write-TestStep "Failed to update incident: $($updateResult.Error)" -Status "Warning"
            $TestResults += @{
                Test = "Incident Update"
                Status = "Warning"
                Duration = $stopwatch.ElapsedMilliseconds
                Message = $updateResult.Error
            }
        }
    }
    else {
        Write-TestStep "Failed to create test incident: $($result.Error)" -Status "Error"
        Write-TestStep "Note: This may indicate insufficient permissions" -Status "Warning"
        
        $TestResults += @{
            Test = "Incident Creation"
            Status = "Failed"
            Duration = $stopwatch.ElapsedMilliseconds
            Message = $result.Error
        }
    }
}
else {
    Write-TestStep "TEST 4: Incident creation test skipped (disabled)" -Status "Info"
}

# Summary
Write-Host "`n" + ("═" * 75) -ForegroundColor Cyan
Write-Host "ServiceNow Connectivity Test Complete!" -ForegroundColor Green
Write-Host ("═" * 75) -ForegroundColor Cyan

$passedTests = ($TestResults | Where-Object { $_.Status -eq "Passed" }).Count
$failedTests = ($TestResults | Where-Object { $_.Status -eq "Failed" }).Count
$warningTests = ($TestResults | Where-Object { $_.Status -eq "Warning" }).Count
$totalTests = $TestResults.Count

Write-Host "`nTest Summary:" -ForegroundColor Yellow
Write-Host "  Total Tests: $totalTests" -ForegroundColor White
Write-Host "  ✓ Passed:    $passedTests" -ForegroundColor Green
Write-Host "  ✗ Failed:    $failedTests" -ForegroundColor Red
Write-Host "  ⚠ Warnings:  $warningTests" -ForegroundColor Yellow

Write-Host "`nDetailed Results:" -ForegroundColor Yellow
foreach ($test in $TestResults) {
    $statusIcon = switch ($test.Status) {
        "Passed" { "✓" }
        "Failed" { "✗" }
        "Warning" { "⚠" }
    }
    
    $statusColor = switch ($test.Status) {
        "Passed" { "Green" }
        "Failed" { "Red" }
        "Warning" { "Yellow" }
    }
    
    Write-Host "  $statusIcon $($test.Test): " -ForegroundColor $statusColor -NoNewline
    Write-Host "$($test.Message) " -NoNewline
    Write-Host "($($test.Duration)ms)" -ForegroundColor Gray
}

Write-Host ""

# Exit with appropriate code
if ($failedTests -gt 0) {
    Write-Host "⚠ Some tests failed. Review the results above." -ForegroundColor Red
    exit 1
}
elseif ($warningTests -gt 0) {
    Write-Host "✓ All critical tests passed, but some warnings were encountered." -ForegroundColor Yellow
    exit 0
}
else {
    Write-Host "✓ All tests passed successfully!" -ForegroundColor Green
    exit 0
}
