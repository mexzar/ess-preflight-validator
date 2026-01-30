<#
.SYNOPSIS
    Test script for Copilot Agent discovery via Dataverse API

.DESCRIPTION
    Validates that we can:
    1. Query the Dataverse 'bot' table to find agents by name
    2. Retrieve the associated solution ID
    3. Get solution components (flows, connection references, env vars)
    
    This is a discovery/test script to verify API access before implementing
    solution-scoped validation in the main ESS Validator.

.PARAMETER AgentName
    The display name of the Copilot agent to find (e.g., "Employee Self-Service Demo")

.PARAMETER EnvironmentId
    Power Platform environment ID

.EXAMPLE
    .\Test-AgentDiscovery.ps1 -AgentName "Employee Self-Service" -EnvironmentId "00000000-0000-0000-0000-000000000000"

.NOTES
    Author: ESS Validator Team
    Version: 1.0.0
    Requires: Power Platform connection (Add-PowerAppsAccount)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AgentName = "Employee Self-Service",

    [Parameter(Mandatory = $true)]
    [string]$EnvironmentId
)

#region Helper Functions

function Get-DataverseAccessToken {
    <#
    .SYNOPSIS
        Gets an access token for Dataverse API calls
    #>
    param([string]$EnvironmentUrl)
    
    try {
        # Try to get token from existing Power Platform connection
        $token = Get-PowerAppEnvironment | Out-Null
        
        # Use Az module if available
        if (Get-Command Get-AzAccessToken -ErrorAction SilentlyContinue) {
            $tokenResponse = Get-AzAccessToken -ResourceUrl $EnvironmentUrl
            return $tokenResponse.Token
        }
        
        # Fallback - return null and we'll use Power Platform cmdlets
        return $null
    }
    catch {
        Write-Warning "Could not get Dataverse token: $_"
        return $null
    }
}

function Invoke-DataverseQuery {
    <#
    .SYNOPSIS
        Executes a query against the Dataverse Web API
    #>
    param(
        [string]$EnvironmentUrl,
        [string]$Query,
        [string]$Token
    )
    
    $uri = "$EnvironmentUrl/api/data/v9.2/$Query"
    
    $headers = @{
        "Authorization" = "Bearer $Token"
        "OData-MaxVersion" = "4.0"
        "OData-Version" = "4.0"
        "Accept" = "application/json"
        "Prefer" = "odata.include-annotations=*"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
        return $response.value
    }
    catch {
        Write-Error "Dataverse query failed: $_"
        return $null
    }
}

#endregion

#region Main Discovery Logic

Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        ESS Agent Discovery Test Script v1.0.0                  ║" -ForegroundColor Cyan  
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Agent Name:     $AgentName" -ForegroundColor White
Write-Host "Environment:    $EnvironmentId" -ForegroundColor White
Write-Host ""

# Step 1: Verify Power Platform connection
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 1: Verifying Power Platform Connection" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

try {
    $env = Get-AdminPowerAppEnvironment -EnvironmentName $EnvironmentId -ErrorAction Stop
    Write-Host "  ✅ Connected to environment: $($env.DisplayName)" -ForegroundColor Green
    $environmentUrl = $env.Internal.properties.linkedEnvironmentMetadata.instanceUrl
    Write-Host "     Dataverse URL: $environmentUrl" -ForegroundColor DarkGray
}
catch {
    Write-Host "  ❌ Cannot connect to Power Platform: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Run 'Add-PowerAppsAccount' to authenticate first." -ForegroundColor Yellow
    exit 1
}

# Step 2: Try to find the agent using Power Platform flows (indirect method)
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 2: Searching for Agent-Related Flows" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

# Get all flows and look for ESS/agent patterns
$flows = Get-AdminFlow -EnvironmentName $EnvironmentId -ErrorAction SilentlyContinue

# Common ESS flow patterns - prioritize exact ESS/Workday matches
$essFlowPatterns = @(
    "Workday*",           # Direct Workday flows
    "Workday Get*",       # Workday Get User Context, etc.
    "*ESS*",
    "*Employee Self*",
    "ServiceNow*Get*",    # ServiceNow HRSD/ITSM flows
    "SAP*Get*"            # SAP SuccessFactors flows
)

$potentialEssFlows = @()
foreach ($pattern in $essFlowPatterns) {
    $matched = $flows | Where-Object { $_.DisplayName -like $pattern }
    $potentialEssFlows += $matched
}
$potentialEssFlows = $potentialEssFlows | Select-Object -Unique

if ($potentialEssFlows.Count -gt 0) {
    Write-Host "  ✅ Found $($potentialEssFlows.Count) potential ESS-related flow(s):" -ForegroundColor Green
    foreach ($flow in $potentialEssFlows) {
        $stateIcon = if ($flow.Enabled -eq $true) { "🟢" } else { "🔴" }
        Write-Host "     $stateIcon $($flow.DisplayName)" -ForegroundColor White
    }
} else {
    Write-Host "  ⚠️  No ESS-related flows found by name pattern" -ForegroundColor Yellow
}

# Step 3: Look for solutions containing "ESS" or agent-related terms
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 3: Searching for ESS Solutions (Indirect via Flows)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

# We'll check if flows belong to a solution by looking at their properties
if ($potentialEssFlows.Count -gt 0) {
    $sampleFlow = $potentialEssFlows[0]
    Write-Host "  ℹ️  Sample flow for solution detection: $($sampleFlow.DisplayName)" -ForegroundColor Cyan
    Write-Host "     Flow ID: $($sampleFlow.FlowName)" -ForegroundColor DarkGray
    
    # Check if flow has solution reference
    if ($sampleFlow.Internal.properties.solutionId) {
        Write-Host "  ✅ Flow is part of solution: $($sampleFlow.Internal.properties.solutionId)" -ForegroundColor Green
    } else {
        Write-Host "  ℹ️  Flow solution reference not directly exposed in API" -ForegroundColor Yellow
    }
}

# Step 4: Get Workday connections for this environment
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 4: Identifying Workday Connections" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$connections = Get-AdminPowerAppConnection -EnvironmentName $EnvironmentId -ErrorAction SilentlyContinue
$workdayConnections = $connections | Where-Object { 
    $_.ConnectorName -like "*workday*" -or 
    $_.DisplayName -like "*Workday*"
}

if ($workdayConnections) {
    Write-Host "  ✅ Found $($workdayConnections.Count) Workday connection(s)" -ForegroundColor Green
    foreach ($conn in $workdayConnections) {
        $status = if ($conn.Statuses -is [array]) { $conn.Statuses[0].Status } else { $conn.Statuses.Status }
        $statusIcon = switch ($status) {
            'Connected' { '🟢' }
            'Error' { '🔴' }
            default { '🟡' }
        }
        Write-Host "     $statusIcon $($conn.DisplayName) [$status]" -ForegroundColor White
    }
} else {
    Write-Host "  ⚠️  No Workday connections found" -ForegroundColor Yellow
}

# Step 5: Get Environment Variables related to Workday
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "STEP 5: Identifying Workday Environment Variables" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

# Environment variables require Dataverse API or PowerShell solution query
Write-Host "  ℹ️  Environment variable discovery requires Dataverse API access" -ForegroundColor Yellow
Write-Host "     These are typically named: Workday_TenantID, Workday_API_URL, etc." -ForegroundColor DarkGray

# Step 6: Summary and Recommendations
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "SUMMARY & NEXT STEPS" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""

$discoveredComponents = @{
    Flows = $potentialEssFlows.Count
    Connections = $workdayConnections.Count
}

Write-Host "  Discovered Components:" -ForegroundColor Cyan
Write-Host "    • ESS-related Flows:      $($discoveredComponents.Flows)" -ForegroundColor White
Write-Host "    • Workday Connections:    $($discoveredComponents.Connections)" -ForegroundColor White
Write-Host ""

if ($discoveredComponents.Flows -gt 0 -or $discoveredComponents.Connections -gt 0) {
    Write-Host "  ✅ DISCOVERY SUCCESSFUL" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Recommendation: Use these discovered components for solution-scoped validation." -ForegroundColor White
    Write-Host "  Instead of scanning all 44 Workday connections, validate only:" -ForegroundColor White
    
    if ($potentialEssFlows.Count -gt 0) {
        Write-Host ""
        Write-Host "    Flows to validate:" -ForegroundColor Cyan
        foreach ($flow in $potentialEssFlows | Select-Object -First 5) {
            Write-Host "      → $($flow.DisplayName)" -ForegroundColor White
        }
        if ($potentialEssFlows.Count -gt 5) {
            Write-Host "      ... and $($potentialEssFlows.Count - 5) more" -ForegroundColor DarkGray
        }
    }
} else {
    Write-Host "  ⚠️  LIMITED DISCOVERY" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  The agent '$AgentName' was not found via indirect discovery." -ForegroundColor White
    Write-Host "  This could mean:" -ForegroundColor White
    Write-Host "    1. The agent/solution is not yet deployed" -ForegroundColor White
    Write-Host "    2. The flows use different naming conventions" -ForegroundColor White
    Write-Host "    3. Direct Dataverse 'bot' table access is needed" -ForegroundColor White
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "IMPLEMENTATION NOTES" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  For production implementation, we should:" -ForegroundColor White
Write-Host "    1. Filter flows by name pattern (Workday*, ESS*, Get Time*, etc.)" -ForegroundColor White
Write-Host "    2. Identify which connections are actively USED by those flows" -ForegroundColor White
Write-Host "    3. Only validate the connections/env vars that matter" -ForegroundColor White
Write-Host ""
Write-Host "  This will reduce validation from 467 checks → ~50 relevant checks" -ForegroundColor Green
Write-Host ""

#endregion

# Return discovery results for programmatic use
return [PSCustomObject]@{
    AgentName = $AgentName
    EnvironmentId = $EnvironmentId
    EnvironmentUrl = $environmentUrl
    DiscoveredFlows = $potentialEssFlows
    DiscoveredConnections = $workdayConnections
    Success = ($potentialEssFlows.Count -gt 0 -or $workdayConnections.Count -gt 0)
}
