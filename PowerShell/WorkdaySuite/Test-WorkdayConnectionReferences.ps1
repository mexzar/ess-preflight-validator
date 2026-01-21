<#
.SYNOPSIS
    Validates Workday connection references in Power Platform

.DESCRIPTION
    Checks the status of Workday-related connection references to ensure
    they are properly authenticated and configured.

.PARAMETER EnvironmentId
    Power Platform environment ID containing the Workday solution

.EXAMPLE
    Test-WorkdayConnectionReferences -EnvironmentId "c3446975-d597-e5b4-8724-d5be9e5c4303"

.NOTES
    Connection references must be authenticated by a service account or
    delegated user for the Workday flows to function properly.
#>

function Test-WorkdayConnectionReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    $results = @()

    Write-Host "`n  🔍 Checking Workday connection references..." -ForegroundColor Cyan

    try {
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
        # Common connector names: "shared_workday", "shared_workdayhcm"
        $workdayConnections = $connections | Where-Object { 
            $_.ConnectorName -like "*workday*" -or 
            $_.DisplayName -like "*Workday*"
        }

        if ($workdayConnections) {
            Write-Host "  ✅ Found $($workdayConnections.Count) Workday connection(s)" -ForegroundColor Green
            Write-Host ""
            
            foreach ($conn in $workdayConnections) {
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

                Write-Host "    $statusIcon $($conn.DisplayName)" -ForegroundColor $statusColor
                Write-Host "       Connector: $($conn.ConnectorName)" -ForegroundColor DarkGray
                Write-Host "       Status: $($conn.Statuses.Status)" -ForegroundColor DarkGray
                Write-Host "       Created: $($conn.CreatedTime)" -ForegroundColor DarkGray
                Write-Host ""

                $connStatus = if ($conn.Statuses.Status -eq 'Connected') { 'Passed' } 
                              elseif ($conn.Statuses.Status -eq 'Error') { 'Failed' }
                              else { 'Warning' }

                $results += [PSCustomObject]@{
                    CheckpointId      = "WD-CONN-REF-$($workdayConnections.IndexOf($conn) + 1)"
                    Category          = 'Workday'
                    Priority          = 'High'
                    Status            = $connStatus
                    Result            = "Connection '$($conn.DisplayName)': $($conn.Statuses.Status)"
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

# Export for module use
Export-ModuleMember -Function Test-WorkdayConnectionReferences -ErrorAction SilentlyContinue
