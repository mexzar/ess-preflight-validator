<#
.SYNOPSIS
    Validates Workday connection references in Power Platform

.DESCRIPTION
    Checks the status of Workday-related connection references to ensure
    they are properly authenticated and configured.
    
    Supports solution-scoped validation when ScopedConnections parameter is provided.

.PARAMETER EnvironmentId
    Power Platform environment ID containing the Workday solution

.PARAMETER ScopedConnections
    Optional. Pre-filtered connections from solution discovery. If provided,
    only these connections will be validated (solution-scoped mode).

.EXAMPLE
    Test-WorkdayConnectionReferences -EnvironmentId "00000000-0000-0000-0000-000000000000"

.EXAMPLE
    # Solution-scoped mode
    Test-WorkdayConnectionReferences -EnvironmentId $envId -ScopedConnections $discoveredConnections

.NOTES
    Connection references must be authenticated by a service account or
    delegated user for the Workday flows to function properly.
#>

function Test-WorkdayConnectionReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId,

        [Parameter(Mandatory = $false)]
        [array]$ScopedConnections = $null
    )

    $results = @()
    $isScopedMode = ($null -ne $ScopedConnections -and $ScopedConnections.Count -gt 0)

    if ($isScopedMode) {
        Write-Host "`n  🔍 Checking Workday connections (Solution-Scoped: $($ScopedConnections.Count) connection(s))..." -ForegroundColor Cyan
    } else {
        Write-Host "`n  🔍 Checking Workday connection references..." -ForegroundColor Cyan
    }

    try {
        # Use scoped connections if provided, otherwise get all
        if ($isScopedMode) {
            $workdayConnections = $ScopedConnections
        } else {
            # Get all connections in the environment
            $connections = Get-AdminPowerAppConnection -EnvironmentName $EnvironmentId -ErrorAction SilentlyContinue

            if (-not $connections) {
                Write-Host "  ⚠️  No connections found or insufficient permissions" -ForegroundColor Yellow
                $results += [PSCustomObject]@{
                    CheckpointId = 'WD-CONN-REF-000'
                    Category     = 'Workday'
                    Priority     = 'High'
                    Status       = 'Warning'
                    Result       = 'Unable to query connections - verify permissions'
                    Remediation  = 'Grant Power Platform Administrator role or Environment Admin permissions'
                }
                return $results
            }

            # Filter for Workday-related connections
            $workdayConnections = $connections | Where-Object { 
                $_.ConnectorName -like "*workday*" -or 
                $_.DisplayName -like "*Workday*"
            }
        }

        if ($workdayConnections) {
            Write-Host "  ✅ Found $($workdayConnections.Count) Workday connection(s)" -ForegroundColor Green
            Write-Host ""
            
            $connIndex = 0
            foreach ($conn in $workdayConnections) {
                $connIndex++
                $statusIcon = switch ($conn.ConnectionStatus) {
                    'Connected' { '✅' }
                    'Error' { '❌' }
                    default { '⚠️' }
                }
                
                $statusColor = switch ($conn.ConnectionStatus) {
                    'Connected' { 'Green' }
                    'Error' { 'Red' }
                    default { 'Yellow' }
                }

                # Get primary status (first entry, or check for any Connected/Error status)
                $primaryStatus = if ($conn.Statuses -is [array]) { $conn.Statuses[0].Status } else { $conn.Statuses.Status }
                
                Write-Host "    $statusIcon $($conn.DisplayName)" -ForegroundColor $statusColor
                Write-Host "       Connector: $($conn.ConnectorName)" -ForegroundColor DarkGray
                Write-Host "       Status: $primaryStatus" -ForegroundColor DarkGray
                Write-Host "       Created: $($conn.CreatedTime)" -ForegroundColor DarkGray
                Write-Host ""

                $connStatus = if ($primaryStatus -eq 'Connected') { 'Passed' } 
                              elseif ($primaryStatus -eq 'Error') { 'Failed' }
                              else { 'Warning' }

                $results += [PSCustomObject]@{
                    CheckpointId      = "WD-CONN-REF-$connIndex"
                    Category          = 'Workday'
                    Priority          = 'High'
                    Status            = $connStatus
                    Result            = "Connection '$($conn.DisplayName)': $primaryStatus"
                    Remediation       = if ($connStatus -ne 'Passed') { 
                        'Re-authenticate the Workday connection in Power Platform > Connections'
                    } else { '' }
                    DocumentationLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-3-connection-references'
                    ConnectionId      = $conn.ConnectionId
                    ConnectorName     = $conn.ConnectorName
                }
            }
        } else {
            Write-Host "  ℹ️  No Workday connections found" -ForegroundColor Gray
            Write-Host "     This is expected if Workday solution is not yet installed" -ForegroundColor DarkGray
            
            $results += [PSCustomObject]@{
                CheckpointId = 'WD-CONN-REF-001'
                Category     = 'Workday'
                Priority     = 'High'
                Status       = 'NotConfigured'
                Result       = 'No Workday connections found in environment'
                Remediation  = 'Install Workday solution and configure connection references'
                DocumentationLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-3-connection-references'
            }
        }

        # Also check for HTTP with Azure AD connections (used for custom Workday calls)
        $httpConnections = $connections | Where-Object { 
            $_.ConnectorName -like "*azuread*" -or 
            $_.ConnectorName -like "*http*"
        }

        if ($httpConnections) {
            Write-Host "  ℹ️  Found $($httpConnections.Count) HTTP/Azure AD connection(s) (may be used for Workday)" -ForegroundColor DarkGray
        }

    } catch {
        Write-Host "  ❌ Error checking connections: $_" -ForegroundColor Red
        $results += [PSCustomObject]@{
            CheckpointId = 'WD-CONN-REF-000'
            Category     = 'Workday'
            Priority     = 'High'
            Status       = 'Failed'
            Result       = "Error querying connection references: $_"
            Remediation  = 'Verify Power Platform permissions and connectivity'
        }
    }

    return $results
}

# Export for module use (only when loaded as module)
if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function Test-WorkdayConnectionReferences
}
