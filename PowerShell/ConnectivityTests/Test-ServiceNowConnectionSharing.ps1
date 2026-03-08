<#
.SYNOPSIS
    Validates ServiceNow connections in Power Platform are properly shared with all users.

.DESCRIPTION
    Standalone script that checks whether each ServiceNow connection in a Power Platform
    environment has been shared with the entire tenant. Unshared connections prevent flows
    from executing under other users' context, which is required for Employee Self-Service.

    The script filters for active ServiceNow connections (ConnectorName matching '*servicenow*'
    with a Connected status) and verifies each one has a Tenant-level role assignment.

    Self-contained authentication: the script checks for an active Power Platform session
    and calls Add-PowerAppsAccount if needed.

.PARAMETER EnvironmentId
    Power Platform environment ID (GUID) containing the ServiceNow solution.

.EXAMPLE
    Test-ServiceNowConnectionSharing -EnvironmentId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
    # Dot-source then call
    . .\Test-ServiceNowConnectionSharing.ps1
    $results = Test-ServiceNowConnectionSharing -EnvironmentId $envId
    $results | Format-Table CheckpointId, Status, Result -AutoSize

.NOTES
    Reference: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/servicenow
    All ServiceNow connections must be shared with the entire organization (Tenant principal)
    for ESS flows to run correctly under each employee's context.
#>

function Test-ServiceNowConnectionSharing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    $results = @()
    $docLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/servicenow'

    # ── Self-contained authentication ────────────────────────────────────────
    Write-Host "`n  🔐 Verifying Power Platform session..." -ForegroundColor Cyan
    try {
        $null = Get-AdminPowerAppEnvironment -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "  ℹ️  No active session detected — launching Add-PowerAppsAccount..." -ForegroundColor Yellow
        Add-PowerAppsAccount
    }

    # ── Retrieve connections ─────────────────────────────────────────────────
    Write-Host "  🔍 Querying ServiceNow connections in environment..." -ForegroundColor Cyan

    try {
        $allConnections = Get-AdminPowerAppConnection -EnvironmentName $EnvironmentId -ErrorAction Stop
    }
    catch {
        Write-Host "  ❌ Failed to query connections: $_" -ForegroundColor Red
        return @([PSCustomObject]@{
            CheckpointId      = 'SN-SHARE-001'
            Category          = 'ServiceNow'
            Priority          = 'High'
            Status            = 'Failed'
            Result            = "Unable to query connections: $_"
            Remediation       = 'Verify Power Platform Administrator permissions and environment ID'
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = 'Connection query failed — check permissions or environment ID'
            Confidence        = 'High'
            GatingSignal      = 'Advisory'
        })
    }

    # Filter for active ServiceNow connections
    $snConnections = $allConnections | Where-Object {
        $_.ConnectorName -like '*servicenow*' -and $_.Statuses[0].Status -eq 'Connected'
    }

    if (-not $snConnections -or $snConnections.Count -eq 0) {
        Write-Host "  ⚠️  No ServiceNow connections found" -ForegroundColor Yellow
        return @([PSCustomObject]@{
            CheckpointId      = 'SN-SHARE-001'
            Category          = 'ServiceNow'
            Priority          = 'High'
            Status            = 'NotConfigured'
            Result            = 'No active ServiceNow connections found in environment'
            Remediation       = 'No ServiceNow connections found. Install the ServiceNow accelerator package first.'
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = 'ServiceNow connector not present or no connections have a Connected status'
            Confidence        = 'High'
            GatingSignal      = 'Advisory'
        })
    }

    Write-Host "  ✅ Found $($snConnections.Count) active ServiceNow connection(s)" -ForegroundColor Green
    Write-Host ""

    # ── Evaluate sharing per connection ──────────────────────────────────────
    $passCount = 0
    $totalChecked = 0

    foreach ($conn in $snConnections) {
        $totalChecked++
        $name = $conn.DisplayName ?? $conn.ConnectionName

        # Query role assignments for this connection
        try {
            $roles = Get-AdminPowerAppConnectionRoleAssignment `
                        -ConnectionName $conn.ConnectionName `
                        -EnvironmentName $EnvironmentId `
                        -ErrorAction Stop
        }
        catch {
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-SHARE-001'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "Failed to query role assignments for '$name': $_"
                Remediation       = 'Verify admin permissions to read connection role assignments'
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = "Role assignment query error for connection '$name'"
                Confidence        = 'High'
                GatingSignal      = 'Advisory'
            }
            Write-Host "    ❌ '$name': failed to query role assignments" -ForegroundColor Red
            continue
        }

        # Check whether any role assignment grants tenant-wide access
        $sharedWithEveryone = $false
        if ($roles) {
            $sharedWithEveryone = ($roles | Where-Object {
                $_.PrincipalType -eq 'Tenant'
            }) -ne $null
        }

        if ($sharedWithEveryone) {
            $passCount++
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-SHARE-001'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Passed'
                Result            = "ServiceNow connection '$name' is shared with the entire organization"
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = ''
                Confidence        = 'High'
                GatingSignal      = 'Advisory'
            }
            Write-Host "    ✅ '$name' — shared with organization" -ForegroundColor Green
        }
        else {
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-SHARE-001'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "ServiceNow connection '$name' is NOT shared with the entire organization"
                Remediation       = "Open Power Platform Admin Center > Connections > '$name' > Share > add the entire organization (Tenant)"
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = "ServiceNow connection `"$name`" is not shared with all users in the environment"
                Confidence        = 'High'
                GatingSignal      = 'Advisory'
            }
            Write-Host "    ❌ '$name' — NOT shared" -ForegroundColor Red
        }
    }

    Write-Host ""
    return $results
}

# Export for module use (only when loaded as module)
try { Export-ModuleMember -Function Test-ServiceNowConnectionSharing } catch { }
