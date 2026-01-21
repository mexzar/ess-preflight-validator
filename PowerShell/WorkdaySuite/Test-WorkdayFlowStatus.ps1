<#
.SYNOPSIS
    Validates Workday Power Automate flow status

.DESCRIPTION
    Checks that Workday-related flows are:
    - Present in the environment
    - Enabled (turned on)
    - Not in a failed/suspended state
    - Properly connected

.PARAMETER EnvironmentId
    Power Platform environment ID containing the Workday solution

.EXAMPLE
    Test-WorkdayFlowStatus -EnvironmentId "c3446975-d597-e5b4-8724-d5be9e5c4303"

.NOTES
    ESS Workday integration typically includes flows for:
    - User context retrieval
    - Employee data synchronization
    - Time-off requests
#>

function Test-WorkdayFlowStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    $results = @()

    Write-Host "`n  🔍 Checking Workday flow status..." -ForegroundColor Cyan

    try {
        # Get all flows in the environment
        $flows = Get-AdminFlow -EnvironmentName $EnvironmentId -ErrorAction SilentlyContinue

        if (-not $flows) {
            Write-Host "  ⚠️  No flows found or insufficient permissions" -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                CheckpointId = 'WD-FLOW-000'
                Category     = 'Workday'
                Priority     = 'High'
                Status       = 'Warning'
                Result       = 'Unable to query flows - verify permissions'
                Remediation  = 'Grant Power Platform Administrator role or Flow Admin permissions'
            }
            return $results
        }

        # Filter for Workday-related flows
        $workdayFlows = $flows | Where-Object { 
            $_.DisplayName -like "*Workday*" -or 
            $_.DisplayName -like "*WD*" -or
            $_.DisplayName -like "*Employee Context*"
        }

        if ($workdayFlows) {
            Write-Host "  ✅ Found $($workdayFlows.Count) Workday-related flow(s)" -ForegroundColor Green
            Write-Host ""
            
            $flowIndex = 0
            foreach ($flow in $workdayFlows) {
                $flowIndex++
                
                # Determine flow state
                $flowState = $flow.Enabled
                $statusIcon = if ($flowState) { '✅' } else { '❌' }
                $statusColor = if ($flowState) { 'Green' } else { 'Red' }
                $flowStatus = if ($flowState) { 'Enabled' } else { 'Disabled' }

                Write-Host "    $statusIcon $($flow.DisplayName)" -ForegroundColor $statusColor
                Write-Host "       State: $flowStatus" -ForegroundColor DarkGray
                Write-Host "       Type: $($flow.FlowType)" -ForegroundColor DarkGray
                Write-Host "       Modified: $($flow.LastModifiedTime)" -ForegroundColor DarkGray
                
                # Check for any error state
                if ($flow.FlowFailureAlertSubscribed) {
                    Write-Host "       ⚠️  Flow failure alerts enabled (may indicate issues)" -ForegroundColor Yellow
                }
                
                Write-Host ""

                $checkStatus = if ($flowState) { 'Passed' } else { 'Failed' }

                $results += [PSCustomObject]@{
                    CheckpointId      = "WD-FLOW-$('{0:D3}' -f $flowIndex)"
                    Category          = 'Workday'
                    Priority          = 'Critical'
                    Status            = $checkStatus
                    Result            = "Flow '$($flow.DisplayName)': $flowStatus"
                    Remediation       = if (-not $flowState) { 
                        "Enable the flow: Power Platform > Solutions > Workday > Cloud Flows > '$($flow.DisplayName)' > Turn On"
                    } else { '' }
                    DocumentationLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday'
                    FlowId            = $flow.FlowName
                    FlowDisplayName   = $flow.DisplayName
                    FlowEnabled       = $flowState
                }
            }

            # Summary
            $enabledCount = ($workdayFlows | Where-Object Enabled -eq $true).Count
            $disabledCount = ($workdayFlows | Where-Object Enabled -eq $false).Count

            Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
            Write-Host "  Summary: $enabledCount enabled, $disabledCount disabled" -ForegroundColor Cyan
            
            if ($disabledCount -gt 0) {
                Write-Host "  ⚠️  $disabledCount flow(s) are disabled and need to be turned on!" -ForegroundColor Yellow
            }

        } else {
            Write-Host "  ℹ️  No Workday flows found" -ForegroundColor Gray
            Write-Host "     This is expected if Workday solution is not yet installed" -ForegroundColor DarkGray
            
            $results += [PSCustomObject]@{
                CheckpointId = 'WD-FLOW-001'
                Category     = 'Workday'
                Priority     = 'High'
                Status       = 'NotConfigured'
                Result       = 'No Workday flows found in environment'
                Remediation  = 'Install Workday solution from ESS deployment package'
                DocumentationLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday'
            }
        }

        # Check for any flows that might be in error state
        $errorFlows = $flows | Where-Object { 
            $_.DisplayName -like "*Workday*" -and 
            $_.FlowSuspensionReason -ne $null 
        }

        if ($errorFlows) {
            foreach ($errorFlow in $errorFlows) {
                Write-Host "  ❌ SUSPENDED: $($errorFlow.DisplayName)" -ForegroundColor Red
                Write-Host "     Reason: $($errorFlow.FlowSuspensionReason)" -ForegroundColor Red
                
                $results += [PSCustomObject]@{
                    CheckpointId = "WD-FLOW-ERR-$($errorFlows.IndexOf($errorFlow) + 1)"
                    Category     = 'Workday'
                    Priority     = 'Critical'
                    Status       = 'Failed'
                    Result       = "Flow '$($errorFlow.DisplayName)' is SUSPENDED: $($errorFlow.FlowSuspensionReason)"
                    Remediation  = 'Fix the flow error and re-enable. Common issues: expired connections, permission changes, or trigger failures.'
                }
            }
        }

    } catch {
        Write-Host "  ❌ Error checking flows: $_" -ForegroundColor Red
        $results += [PSCustomObject]@{
            CheckpointId = 'WD-FLOW-000'
            Category     = 'Workday'
            Priority     = 'High'
            Status       = 'Failed'
            Result       = "Error querying flow status: $_"
            Remediation  = 'Verify Power Platform permissions and connectivity'
        }
    }

    return $results
}

# Export for module use
Export-ModuleMember -Function Test-WorkdayFlowStatus -ErrorAction SilentlyContinue
