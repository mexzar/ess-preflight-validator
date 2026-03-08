<#
.SYNOPSIS
    Validates Workday SOAP connections in Power Platform are properly shared with all users.

.DESCRIPTION
    Standalone script that checks whether each Workday SOAP connection in a Power Platform
    environment has been shared with the entire tenant. Unshared connections prevent flows
    from executing under other users' context, which is required for Employee Self-Service.

    The script auto-detects three expected connection types by DisplayName pattern:
      - OAuth User connection (matches 'oauth', 'oauthuser', 'user.*oauth')
      - ISU_WQL connection     (matches 'wql', 'context', 'isu.*wql')
      - ISU_Generic connection (matches 'generic', 'isu.*generic')

    Self-contained authentication: the script checks for an active Power Platform session
    and calls Add-PowerAppsAccount if needed.

.PARAMETER EnvironmentId
    Power Platform environment ID (GUID) containing the Workday solution.

.EXAMPLE
    Test-WorkdayConnectionSharing -EnvironmentId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
    # Dot-source then call
    . .\Test-WorkdayConnectionSharing.ps1
    $results = Test-WorkdayConnectionSharing -EnvironmentId $envId
    $results | Format-Table CheckpointId, Status, Result -AutoSize

.NOTES
    Reference: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-3-connection-references
    All three Workday SOAP connections must be shared with the entire organization (Tenant principal)
    for ESS flows to run correctly under each employee's context.
#>

function Test-WorkdayConnectionSharing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    $results = @()
    $docLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-3-connection-references'

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
    Write-Host "  🔍 Querying Workday SOAP connections in environment..." -ForegroundColor Cyan

    try {
        $allConnections = Get-AdminPowerAppConnection -EnvironmentName $EnvironmentId -ErrorAction Stop
    }
    catch {
        Write-Host "  ❌ Failed to query connections: $_" -ForegroundColor Red
        return @([PSCustomObject]@{
            CheckpointId      = 'WD-SHARE-004'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'Failed'
            Result            = "Unable to query connections: $_"
            Remediation       = 'Verify Power Platform Administrator permissions and environment ID'
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = 'Connection query failed — check permissions or environment ID'
            Confidence        = 'High'
            GatingSignal      = $true
        })
    }

    $workdayConnections = $allConnections | Where-Object { $_.ConnectorName -eq 'shared_workdaysoap' }

    if (-not $workdayConnections -or $workdayConnections.Count -eq 0) {
        Write-Host "  ⚠️  No Workday SOAP connections found" -ForegroundColor Yellow
        return @([PSCustomObject]@{
            CheckpointId      = 'WD-SHARE-004'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'NotConfigured'
            Result            = 'No shared_workdaysoap connections found in environment'
            Remediation       = 'Install the Workday solution and create the three required SOAP connections'
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = 'Workday SOAP connector not present — solution may not be installed'
            Confidence        = 'High'
            GatingSignal      = $true
        })
    }

    Write-Host "  ✅ Found $($workdayConnections.Count) Workday SOAP connection(s)" -ForegroundColor Green
    Write-Host ""

    # ── Auto-detect connection types by DisplayName ──────────────────────────
    $typeMap = @(
        @{
            Label        = 'OAuthUser'
            CheckpointId = 'WD-SHARE-001'
            Patterns     = @('oauth', 'oauthuser', 'user.*oauth')
        },
        @{
            Label        = 'ISU_WQL'
            CheckpointId = 'WD-SHARE-002'
            Patterns     = @('wql', 'context', 'isu.*wql')
        },
        @{
            Label        = 'ISU_Generic'
            CheckpointId = 'WD-SHARE-003'
            Patterns     = @('generic', 'isu.*generic')
        }
    )

    # Classify each Workday connection
    $classified = @{}
    foreach ($conn in $workdayConnections) {
        $displayName = ($conn.DisplayName ?? '').ToLower()
        $matched = $false

        foreach ($type in $typeMap) {
            foreach ($pattern in $type.Patterns) {
                if ($displayName -match $pattern) {
                    $classified[$type.CheckpointId] = $conn
                    $matched = $true
                    break
                }
            }
            if ($matched) { break }
        }

        # If no pattern matched, keep it as unclassified for the summary
        if (-not $matched) {
            # Assign to the first empty slot so we still evaluate sharing
            foreach ($type in $typeMap) {
                if (-not $classified.ContainsKey($type.CheckpointId)) {
                    $classified[$type.CheckpointId] = $conn
                    break
                }
            }
        }
    }

    # ── Evaluate sharing per connection type ─────────────────────────────────
    $passCount = 0
    $totalChecked = 0

    foreach ($type in $typeMap) {
        $cpId = $type.CheckpointId
        $conn = $classified[$cpId]

        if (-not $conn) {
            # Connection type not found
            $results += [PSCustomObject]@{
                CheckpointId      = $cpId
                Category          = 'Workday'
                Priority          = 'High'
                Status            = 'Warning'
                Result            = "$($type.Label) connection not detected among Workday SOAP connections"
                Remediation       = "Create and share the $($type.Label) Workday SOAP connection in Power Platform"
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = "No connection with a DisplayName matching $($type.Label) patterns ($($type.Patterns -join ', '))"
                Confidence        = 'Medium'
                GatingSignal      = $false
            }
            Write-Host "    ⚠️  $($type.Label): not detected" -ForegroundColor Yellow
            continue
        }

        $totalChecked++

        # Query role assignments for this connection
        try {
            $roles = Get-AdminPowerAppConnectionRoleAssignment `
                        -ConnectionName $conn.ConnectionName `
                        -EnvironmentName $EnvironmentId `
                        -ErrorAction Stop
        }
        catch {
            $results += [PSCustomObject]@{
                CheckpointId      = $cpId
                Category          = 'Workday'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "Failed to query role assignments for $($type.Label) ('$($conn.DisplayName)'): $_"
                Remediation       = 'Verify admin permissions to read connection role assignments'
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = "Role assignment query error for connection '$($conn.DisplayName)'"
                Confidence        = 'High'
                GatingSignal      = $true
            }
            Write-Host "    ❌ $($type.Label): failed to query role assignments" -ForegroundColor Red
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
                CheckpointId      = $cpId
                Category          = 'Workday'
                Priority          = 'High'
                Status            = 'Passed'
                Result            = "$($type.Label) connection '$($conn.DisplayName)' is shared with the entire organization"
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = ''
                Confidence        = 'High'
                GatingSignal      = $false
            }
            Write-Host "    ✅ $($type.Label): '$($conn.DisplayName)' — shared with organization" -ForegroundColor Green
        }
        else {
            $results += [PSCustomObject]@{
                CheckpointId      = $cpId
                Category          = 'Workday'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "$($type.Label) connection '$($conn.DisplayName)' is NOT shared with the entire organization"
                Remediation       = "Open Power Platform Admin Center > Connections > '$($conn.DisplayName)' > Share > add the entire organization (Tenant)"
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = "Connection '$($conn.DisplayName)' lacks a role assignment with PrincipalType 'Tenant'. Share the connection with the entire organization so all users' flows can execute."
                Confidence        = 'High'
                GatingSignal      = $true
            }
            Write-Host "    ❌ $($type.Label): '$($conn.DisplayName)' — NOT shared" -ForegroundColor Red
        }
    }

    # ── WD-SHARE-004: Overall sharing summary ────────────────────────────────
    Write-Host ""
    $expectedCount = 3

    if ($workdayConnections.Count -lt $expectedCount) {
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-SHARE-004'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'Warning'
            Result            = "Only $($workdayConnections.Count) of $expectedCount expected Workday SOAP connections found. Detected connections may be shared, but coverage is incomplete."
            Remediation       = "Ensure all three Workday SOAP connections (OAuthUser, ISU_WQL, ISU_Generic) are created and shared with the entire organization"
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = "Expected $expectedCount Workday SOAP connections but found $($workdayConnections.Count). Missing connections will prevent some ESS flows from running."
            Confidence        = 'Medium'
            GatingSignal      = $true
        }
        Write-Host "  ⚠️  Overall: $($workdayConnections.Count) of $expectedCount expected connections found — incomplete coverage" -ForegroundColor Yellow
    }
    elseif ($passCount -eq $totalChecked -and $totalChecked -eq $expectedCount) {
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-SHARE-004'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'Passed'
            Result            = "All $expectedCount Workday SOAP connections are shared with the entire organization"
            Remediation       = ''
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = ''
            Confidence        = 'High'
            GatingSignal      = $false
        }
        Write-Host "  ✅ Overall: All $expectedCount connections shared with organization" -ForegroundColor Green
    }
    else {
        $failedCount = $totalChecked - $passCount
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-SHARE-004'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'Failed'
            Result            = "$failedCount of $totalChecked Workday SOAP connection(s) are NOT shared with the organization"
            Remediation       = 'Share all Workday SOAP connections with the entire organization in Power Platform Admin Center'
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = "$failedCount connection(s) missing tenant-wide role assignment. Unshared connections block ESS flows for other users."
            Confidence        = 'High'
            GatingSignal      = $true
        }
        Write-Host "  ❌ Overall: $failedCount of $totalChecked connection(s) not shared" -ForegroundColor Red
    }

    Write-Host ""
    return $results
}

# Export for module use (only when loaded as module)
try { Export-ModuleMember -Function Test-WorkdayConnectionSharing } catch { }
