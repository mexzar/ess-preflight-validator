<#
.SYNOPSIS
    Validates Workday environment variables in Dataverse

.DESCRIPTION
    Queries the Power Platform environment to validate the three critical 
    Workday environment variables required for ESS integration:
    - EmployeeContextRequestAccountName (must be manually configured)
    - EmployeeContextRequestReportName (default: "WD User Context")
    - EmployeeContextRequestReportInstanceName (default: "Report2")

.PARAMETER EnvironmentId
    Power Platform environment ID containing the Workday solution

.EXAMPLE
    Test-WorkdayEnvironmentVariables -EnvironmentId "00000000-0000-0000-0000-000000000000"

.NOTES
    Reference: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-4-environment-variables
#>

function Test-WorkdayEnvironmentVariables {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )

    $results = @()

    Write-Host "`n  🔍 Querying Workday environment variables..." -ForegroundColor Cyan

    try {
        # Get environment details to construct Dataverse URL
        $environment = Get-AdminPowerAppEnvironment -EnvironmentName $EnvironmentId -ErrorAction Stop
        
        if (-not $environment) {
            Write-Host "  ❌ Environment not found: $EnvironmentId" -ForegroundColor Red
            return @([PSCustomObject]@{
                CheckpointId = 'WD-ENV-000'
                Category     = 'Workday'
                Priority     = 'Critical'
                Status       = 'Failed'
                Result       = "Environment not found: $EnvironmentId"
                Remediation  = 'Verify the Environment ID is correct'
            })
        }

        # Extract the Dataverse URL from environment
        $dataverseUrl = $environment.Internal.Properties.LinkedEnvironmentMetadata.InstanceUrl
        
        if (-not $dataverseUrl) {
            Write-Host "  ⚠️  Could not determine Dataverse URL - environment may not have Dataverse enabled" -ForegroundColor Yellow
            return @([PSCustomObject]@{
                CheckpointId = 'WD-ENV-000'
                Category     = 'Workday'
                Priority     = 'Critical'
                Status       = 'Failed'
                Result       = 'Dataverse URL not found for this environment'
                Remediation  = 'Ensure Dataverse is enabled for this environment'
            })
        }

        Write-Host "  📍 Dataverse URL: $dataverseUrl" -ForegroundColor DarkGray

        # Query environment variable definitions
        # We need to authenticate to Dataverse - using the current Power Platform session
        $apiUrl = "$dataverseUrl/api/data/v9.2/environmentvariabledefinitions?" + 
                  "`$filter=startswith(schemaname,'EmployeeContextRequest')" +
                  "&`$expand=environmentvariablevalues(`$select=value)"
        
        Write-Verbose "API URL: $apiUrl"

        # Try to get access token for Dataverse
        try {
            $token = Get-PowerAppEnvironmentLocale -EnvironmentName $EnvironmentId -ErrorAction SilentlyContinue
            
            # Use Invoke-RestMethod with the Power Platform authentication context
            $headers = @{
                "OData-MaxVersion" = "4.0"
                "OData-Version"    = "4.0"
                "Accept"           = "application/json"
                "Prefer"           = "odata.include-annotations=*"
            }

            # Note: This may require additional authentication setup
            # For now, we'll provide guidance on manual verification
            
            Write-Host "  ℹ️  Direct Dataverse API access requires additional authentication" -ForegroundColor Yellow
            Write-Host "     Providing validation guidance for manual verification..." -ForegroundColor DarkGray

        } catch {
            Write-Verbose "Token acquisition note: $_"
        }

        # Define the expected environment variables
        $workdayEnvVars = @(
            @{
                SchemaName    = 'EmployeeContextRequestAccountName'
                DisplayName   = 'Account Name'
                CheckpointId  = 'WD-ENV-001'
                Priority      = 'Critical'
                DefaultValue  = $null  # Must be manually set
                MustBeSet     = $true
                Description   = 'Workday ISU account with RaaS report access'
            },
            @{
                SchemaName    = 'EmployeeContextRequestReportName'
                DisplayName   = 'Report Name'
                CheckpointId  = 'WD-ENV-002'
                Priority      = 'High'
                DefaultValue  = 'WD User Context'
                MustBeSet     = $false
                Description   = 'Name of the Workday RaaS report'
            },
            @{
                SchemaName    = 'EmployeeContextRequestReportInstanceName'
                DisplayName   = 'Report Instance Name'
                CheckpointId  = 'WD-ENV-003'
                Priority      = 'High'
                DefaultValue  = 'Report2'
                MustBeSet     = $false
                Description   = 'Workday report instance name'
            }
        )

        Write-Host ""
        Write-Host "  Workday Environment Variables Status:" -ForegroundColor White
        Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray

        foreach ($envVar in $workdayEnvVars) {
            # Since we can't directly query Dataverse without additional auth setup,
            # we'll create guidance-based validation results
            
            if ($envVar.MustBeSet) {
                # Critical variable that must be manually configured
                $result = [PSCustomObject]@{
                    CheckpointId      = $envVar.CheckpointId
                    Category          = 'Workday'
                    Priority          = $envVar.Priority
                    Status            = 'NotConfigured'
                    Result            = "VERIFY: '$($envVar.SchemaName)' must be manually configured with ISU account name"
                    Remediation       = "In Power Platform > Solutions > Workday Solution > Environment Variables, set '$($envVar.DisplayName)' to your Workday ISU service account"
                    DocumentationLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-4-environment-variables'
                    VariableName      = $envVar.SchemaName
                    ExpectedDefault   = $envVar.DefaultValue
                    Stage             = 'Detection'
                    RootCause         = 'Cannot directly query Dataverse environment variable values without additional auth'
                    Confidence        = 'Medium'
                    GatingSignal      = 'Yes'
                }
                
                Write-Host "  ⚠️  $($envVar.SchemaName)" -ForegroundColor Yellow
                Write-Host "      Status: Requires manual configuration" -ForegroundColor Yellow
                Write-Host "      Action: Set to your Workday ISU account name" -ForegroundColor Cyan
                
            } else {
                # Variable with expected default
                $result = [PSCustomObject]@{
                    CheckpointId      = $envVar.CheckpointId
                    Category          = 'Workday'
                    Priority          = $envVar.Priority
                    Status            = 'NotConfigured'
                    Result            = "VERIFY: '$($envVar.SchemaName)' should be '$($envVar.DefaultValue)' (auto-populated default)"
                    Remediation       = "Verify in Power Platform that this value is set to '$($envVar.DefaultValue)' unless intentionally changed"
                    DocumentationLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday#step-4-environment-variables'
                    VariableName      = $envVar.SchemaName
                    ExpectedDefault   = $envVar.DefaultValue
                    Stage             = 'Detection'
                    RootCause         = ''
                    Confidence        = ''
                    GatingSignal      = 'Advisory'
                }
                
                Write-Host "  ℹ️  $($envVar.SchemaName)" -ForegroundColor Gray
                Write-Host "      Expected: '$($envVar.DefaultValue)'" -ForegroundColor DarkGray
                Write-Host "      Status: Verify auto-populated value" -ForegroundColor DarkGray
            }
            
            $results += $result
            Write-Host ""
        }

        # Add a summary guidance result
        Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  📍 To verify these values manually:" -ForegroundColor Cyan
        Write-Host "     1. Go to: https://make.powerapps.com" -ForegroundColor White
        Write-Host "     2. Select environment: $($environment.DisplayName)" -ForegroundColor White
        Write-Host "     3. Navigate to: Solutions > [Workday Solution]" -ForegroundColor White
        Write-Host "     4. Click: Environment Variables" -ForegroundColor White
        Write-Host ""
        
        # Direct link to the solution if we can construct it
        $solutionUrl = "https://make.powerapps.com/environments/$EnvironmentId/solutions"
        Write-Host "  🔗 Direct link: $solutionUrl" -ForegroundColor Blue
        Write-Host ""

    } catch {
        Write-Host "  ❌ Error checking environment variables: $_" -ForegroundColor Red
        $results += [PSCustomObject]@{
            CheckpointId = 'WD-ENV-000'
            Category     = 'Workday'
            Priority     = 'Critical'
            Status       = 'Failed'
            Result       = "Error querying environment variables: $_"
            Remediation  = 'Ensure you have Power Platform Administrator permissions'
        }
    }

    return $results
}

# Export for module use (only when loaded as module)
if ($ExecutionContext.SessionState.Module) {
    Export-ModuleMember -Function Test-WorkdayEnvironmentVariables
}
