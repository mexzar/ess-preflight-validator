<#
.SYNOPSIS
    Validates the Workday RaaS "WD User Context" report structure.

.DESCRIPTION
    Standalone PowerShell script that validates the Workday Report-as-a-Service (RaaS)
    "WD_User_Context" report is accessible, returns expected columns, calculated fields,
    and contains populated data rows.

    This script performs five checkpoint validations:
      WD-RPT-001: Report accessible (Critical)
      WD-RPT-002: Required columns present (Critical)
      WD-RPT-003: Calculated fields present (High)
      WD-RPT-004: Report returns data rows (High)
      WD-RPT-005: Column data quality (Medium)

    Uses Basic authentication (username@tenant:password) against the RaaS GET endpoint.
    If parameters are not supplied, the script prompts interactively.

.PARAMETER EnvironmentId
    Optional Power Platform environment ID. Not required for standalone execution
    but accepted for compatibility with the validation suite orchestrator.

.PARAMETER WorkdayTenant
    Workday tenant identifier (e.g., "contoso_impl"). Prompted if not provided.

.PARAMETER Username
    Workday ISU username (without @tenant suffix). Prompted if not provided.

.PARAMETER Password
    SecureString password for the Workday ISU account. Prompted if not provided.

.PARAMETER WorkdayBaseUrl
    Base URL for the Workday services endpoint.
    Defaults to "https://wd2-impl-services1.workday.com".

.EXAMPLE
    # Interactive — prompts for all credentials
    .\Test-WorkdayReportStructure.ps1

.EXAMPLE
    # Fully parameterised
    $secPwd = Read-Host "Password" -AsSecureString
    Test-WorkdayReportStructure -WorkdayTenant "contoso_impl" `
        -Username "ISU_COPILOT" -Password $secPwd

.EXAMPLE
    # Custom Workday URL
    Test-WorkdayReportStructure -WorkdayTenant "contoso" `
        -Username "ISU_COPILOT" -Password $secPwd `
        -WorkdayBaseUrl "https://wd5-services1.workday.com"

.NOTES
    Author  : ESS Validator Team
    Version : 1.0.0
    Requires: PowerShell 5.1+
    Reference: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday
#>

function Test-WorkdayReportStructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$EnvironmentId,

        [Parameter(Mandatory = $false)]
        [string]$WorkdayTenant,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [System.Security.SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [string]$WorkdayBaseUrl = "https://wd2-impl-services1.workday.com"
    )

    #region Constants
    $docLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/workday'

    $requiredColumns = @(
        'Employee_ID',
        'Legal_Name',
        'Legal_First_Name',
        'Legal_Last_Name',
        'Work_Email',
        'Manager_Name',
        'Job_Title',
        'Business_Title',
        'Location',
        'Cost_Center',
        'Company',
        'Supervisory_Organization',
        'Worker_Type'
    )

    $calculatedFields = @(
        'Is_Manager',
        'Is_Terminated',
        'Has_Direct_Reports'
    )
    #endregion

    #region Interactive Prompts
    if (-not $WorkdayTenant) {
        $WorkdayTenant = Read-Host "Enter Workday Tenant (e.g., contoso_impl)"
    }
    if (-not $Username) {
        $Username = Read-Host "Enter Workday ISU Username (without @tenant)"
    }
    if (-not $Password) {
        $Password = Read-Host "Enter Workday Password" -AsSecureString
    }
    #endregion

    $results = @()

    #region Build Auth Header
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    try {
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }

    $base64Auth = [Convert]::ToBase64String(
        [System.Text.Encoding]::UTF8.GetBytes("${Username}@${WorkdayTenant}:${plainPassword}")
    )

    $headers = @{
        'Authorization' = "Basic $base64Auth"
        'Accept'        = 'application/xml'
    }

    # Clear plain-text password from memory
    $plainPassword = $null
    #endregion

    #region Build RaaS URL
    $raasUrl = "$WorkdayBaseUrl/ccx/service/customreport2/$WorkdayTenant/ISU_WQL_COPILOT/WD_User_Context?format=simplexml"
    #endregion

    Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       Workday RaaS Report Structure Validation                ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📍 Tenant  : $WorkdayTenant" -ForegroundColor Gray
    Write-Host "📍 User    : $Username" -ForegroundColor Gray
    Write-Host "📍 Endpoint: $raasUrl" -ForegroundColor Gray
    Write-Host ""

    #region WD-RPT-001 — Report Accessible
    Write-Host "🔍 WD-RPT-001: Testing RaaS report accessibility..." -ForegroundColor Cyan
    $responseXml = $null

    try {
        $response = Invoke-WebRequest -Uri $raasUrl -Headers $headers -Method Get -UseBasicParsing -ErrorAction Stop

        if ($response.StatusCode -eq 200) {
            [xml]$responseXml = $response.Content

            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-RPT-001'
                Category          = 'Workday'
                Priority          = 'Critical'
                Status            = 'Passed'
                Result            = 'RaaS report WD_User_Context is accessible'
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = ''
                Confidence        = ''
                GatingSignal      = 'Yes'
            }
            Write-Host "   ✅ Report accessible (HTTP 200)" -ForegroundColor Green
        }
        else {
            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-RPT-001'
                Category          = 'Workday'
                Priority          = 'Critical'
                Status            = 'Failed'
                Result            = "RaaS report returned unexpected HTTP status: $($response.StatusCode)"
                Remediation       = 'Verify the Workday tenant, ISU credentials, and report name. Ensure ISU_WQL_COPILOT owns the WD_User_Context report.'
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = "HTTP $($response.StatusCode) returned from RaaS endpoint"
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
            Write-Host "   ❌ Unexpected HTTP status: $($response.StatusCode)" -ForegroundColor Red
        }
    }
    catch {
        $errMsg = $_.Exception.Message
        $rootCause = 'Unknown error calling RaaS endpoint'
        $remediation = 'Verify the Workday base URL, tenant name, ISU username, and password are correct. Ensure the ISU account has access to the WD_User_Context report.'

        if ($errMsg -match '401|Unauthorized') {
            $rootCause = 'Authentication failed — invalid ISU credentials or account locked'
            $remediation = 'Verify the ISU username and password. Ensure the account is not locked or expired in Workday. Credentials must be in the form username@tenant.'
        }
        elseif ($errMsg -match '403|Forbidden') {
            $rootCause = 'ISU account lacks permission to access the WD_User_Context report'
            $remediation = 'Grant the ISU_WQL_COPILOT integration system user access to the WD_User_Context custom report in Workday security policies.'
        }
        elseif ($errMsg -match '404|Not Found') {
            $rootCause = 'Report WD_User_Context not found — verify report owner and name'
            $remediation = 'Ensure the custom report WD_User_Context exists under the ISU_WQL_COPILOT report owner in Workday. Check for typos in tenant or report name.'
        }
        elseif ($errMsg -match 'Could not resolve|NameResolutionFailure|ConnectFailure|timeout') {
            $rootCause = "Cannot reach Workday endpoint: $WorkdayBaseUrl"
            $remediation = "Verify the Workday base URL is correct and reachable from this network. Check firewall and proxy settings."
        }

        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-001'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'Failed'
            Result            = "RaaS report WD_User_Context is not accessible: $errMsg"
            Remediation       = $remediation
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = $rootCause
            Confidence        = 'High'
            GatingSignal      = 'Yes'
        }
        Write-Host "   ❌ Report not accessible: $errMsg" -ForegroundColor Red

        # Cannot continue without a valid response — return early with remaining checks as NotConfigured
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-002'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'NotConfigured'
            Result            = 'Cannot validate required columns — report not accessible'
            Remediation       = 'Resolve WD-RPT-001 first'
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = ''
            Confidence        = ''
            GatingSignal      = 'Yes'
        }
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-003'
            Category          = 'Workday'
            Priority          = 'High'
            Status            = 'NotConfigured'
            Result            = 'Cannot validate calculated fields — report not accessible'
            Remediation       = 'Resolve WD-RPT-001 first'
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = ''
            Confidence        = ''
            GatingSignal      = 'No'
        }
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-004'
            Category          = 'Workday'
            Priority          = 'High'
            Status            = 'NotConfigured'
            Result            = 'Cannot validate data rows — report not accessible'
            Remediation       = 'Resolve WD-RPT-001 first'
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = ''
            Confidence        = ''
            GatingSignal      = 'No'
        }
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-005'
            Category          = 'Workday'
            Priority          = 'Medium'
            Status            = 'NotConfigured'
            Result            = 'Cannot validate data quality — report not accessible'
            Remediation       = 'Resolve WD-RPT-001 first'
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = ''
            Confidence        = ''
            GatingSignal      = 'No'
        }

        Write-Host ""
        Write-Host "⚠️  Skipping remaining checks — report not accessible" -ForegroundColor Yellow
        return $results
    }
    #endregion

    # If we got here but responseXml is null (non-200 path), bail out
    if (-not $responseXml) {
        return $results
    }

    #region Discover Column Names from Response XML
    # simplexml format returns <Report_Entry> elements; column names are child element names
    $reportEntries = $responseXml.SelectNodes('//*[local-name()="Report_Entry"]')
    $discoveredColumns = @()

    if ($reportEntries -and $reportEntries.Count -gt 0) {
        $firstEntry = $reportEntries[0]
        foreach ($child in $firstEntry.ChildNodes) {
            if ($child.NodeType -eq 'Element') {
                $discoveredColumns += $child.LocalName
            }
        }
    }
    #endregion

    #region WD-RPT-002 — Required Columns Present
    Write-Host "🔍 WD-RPT-002: Checking required columns..." -ForegroundColor Cyan

    $missingColumns = @()
    foreach ($col in $requiredColumns) {
        if ($col -notin $discoveredColumns) {
            $missingColumns += $col
        }
    }

    if ($missingColumns.Count -eq 0) {
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-002'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'Passed'
            Result            = "All 13 required columns present in WD_User_Context report"
            Remediation       = ''
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = ''
            Confidence        = ''
            GatingSignal      = 'Yes'
        }
        Write-Host "   ✅ All 13 required columns found" -ForegroundColor Green
    }
    else {
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-002'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'Failed'
            Result            = "Missing $($missingColumns.Count) required column(s): $($missingColumns -join ', ')"
            Remediation       = "Add the missing column(s) to the WD_User_Context custom report in Workday Report Designer: $($missingColumns -join ', ')"
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = "Report definition is missing required column(s)"
            Confidence        = 'High'
            GatingSignal      = 'Yes'
        }
        Write-Host "   ❌ Missing columns: $($missingColumns -join ', ')" -ForegroundColor Red
    }
    #endregion

    #region WD-RPT-003 — Calculated Fields Present
    Write-Host "🔍 WD-RPT-003: Checking calculated fields..." -ForegroundColor Cyan

    $missingCalcFields = @()
    foreach ($field in $calculatedFields) {
        if ($field -notin $discoveredColumns) {
            $missingCalcFields += $field
        }
    }

    if ($missingCalcFields.Count -eq 0) {
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-003'
            Category          = 'Workday'
            Priority          = 'High'
            Status            = 'Passed'
            Result            = 'All 3 calculated fields present (Is_Manager, Is_Terminated, Has_Direct_Reports)'
            Remediation       = ''
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = ''
            Confidence        = ''
            GatingSignal      = 'No'
        }
        Write-Host "   ✅ All 3 calculated fields found" -ForegroundColor Green
    }
    else {
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-003'
            Category          = 'Workday'
            Priority          = 'High'
            Status            = 'Failed'
            Result            = "Missing $($missingCalcFields.Count) calculated field(s): $($missingCalcFields -join ', ')"
            Remediation       = "Add the missing calculated field(s) to the WD_User_Context report: $($missingCalcFields -join ', '). These should be computed columns in the Workday report definition."
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = "Report definition is missing calculated field(s)"
            Confidence        = 'High'
            GatingSignal      = 'No'
        }
        Write-Host "   ❌ Missing calculated fields: $($missingCalcFields -join ', ')" -ForegroundColor Red
    }
    #endregion

    #region WD-RPT-004 — Report Returns Data Rows
    Write-Host "🔍 WD-RPT-004: Checking for data rows..." -ForegroundColor Cyan

    $rowCount = 0
    if ($reportEntries) {
        $rowCount = $reportEntries.Count
    }

    if ($rowCount -gt 0) {
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-004'
            Category          = 'Workday'
            Priority          = 'High'
            Status            = 'Passed'
            Result            = "Report returned $rowCount data row(s)"
            Remediation       = ''
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = ''
            Confidence        = ''
            GatingSignal      = 'No'
        }
        Write-Host "   ✅ $rowCount data row(s) returned" -ForegroundColor Green
    }
    else {
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-004'
            Category          = 'Workday'
            Priority          = 'High'
            Status            = 'Warning'
            Result            = 'Report returned 0 data rows'
            Remediation       = 'Verify the report filter criteria in Workday. Ensure the ISU account security profile grants access to worker data. Check that the report is not filtered to an empty population.'
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = 'Report returned no data — possible security or filter misconfiguration'
            Confidence        = 'Medium'
            GatingSignal      = 'No'
        }
        Write-Host "   ⚠️  No data rows returned" -ForegroundColor Yellow
    }
    #endregion

    #region WD-RPT-005 — Column Data Quality
    Write-Host "🔍 WD-RPT-005: Checking column data quality..." -ForegroundColor Cyan

    $keyColumns = @('Employee_ID', 'Legal_Name', 'Work_Email', 'Job_Title', 'Company')
    $emptyKeyColumns = @()

    if ($rowCount -gt 0 -and $reportEntries) {
        foreach ($col in $keyColumns) {
            if ($col -notin $discoveredColumns) {
                # Column missing entirely — already flagged in RPT-002
                continue
            }

            $allEmpty = $true
            foreach ($entry in $reportEntries) {
                $node = $entry.SelectSingleNode("*[local-name()='$col']")
                if ($node -and -not [string]::IsNullOrWhiteSpace($node.InnerText)) {
                    $allEmpty = $false
                    break
                }
            }

            if ($allEmpty) {
                $emptyKeyColumns += $col
            }
        }

        if ($emptyKeyColumns.Count -eq 0) {
            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-RPT-005'
                Category          = 'Workday'
                Priority          = 'Medium'
                Status            = 'Passed'
                Result            = 'Key columns are populated with data across returned rows'
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = ''
                Confidence        = ''
                GatingSignal      = 'No'
            }
            Write-Host "   ✅ Key columns are populated" -ForegroundColor Green
        }
        else {
            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-RPT-005'
                Category          = 'Workday'
                Priority          = 'Medium'
                Status            = 'Warning'
                Result            = "Key column(s) contain no data: $($emptyKeyColumns -join ', ')"
                Remediation       = "Check the report field mappings in Workday for: $($emptyKeyColumns -join ', '). Ensure the data source fields are correctly mapped and the ISU security profile exposes these attributes."
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = 'One or more key columns are returning empty values for all rows'
                Confidence        = 'Medium'
                GatingSignal      = 'No'
            }
            Write-Host "   ⚠️  Empty key columns: $($emptyKeyColumns -join ', ')" -ForegroundColor Yellow
        }
    }
    else {
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-RPT-005'
            Category          = 'Workday'
            Priority          = 'Medium'
            Status            = 'NotConfigured'
            Result            = 'Cannot validate data quality — no data rows returned'
            Remediation       = 'Resolve WD-RPT-004 first'
            DocumentationLink = $docLink
            Stage             = 'Detection'
            RootCause         = ''
            Confidence        = ''
            GatingSignal      = 'No'
        }
        Write-Host "   ⚠️  Skipped — no data rows to evaluate" -ForegroundColor Yellow
    }
    #endregion

    #region Summary
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  Report Structure Validation Summary" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan

    $passed  = ($results | Where-Object { $_.Status -eq 'Passed' }).Count
    $failed  = ($results | Where-Object { $_.Status -eq 'Failed' }).Count
    $warning = ($results | Where-Object { $_.Status -eq 'Warning' }).Count
    $notCfg  = ($results | Where-Object { $_.Status -eq 'NotConfigured' }).Count

    Write-Host "   ✅ Passed : $passed" -ForegroundColor Green
    if ($failed -gt 0)  { Write-Host "   ❌ Failed : $failed" -ForegroundColor Red }
    if ($warning -gt 0) { Write-Host "   ⚠️  Warning: $warning" -ForegroundColor Yellow }
    if ($notCfg -gt 0)  { Write-Host "   ⬜ NotConfigured: $notCfg" -ForegroundColor Gray }
    Write-Host ""
    #endregion

    return $results
}

# Module compatibility — export function when loaded as part of a module
try { Export-ModuleMember -Function Test-WorkdayReportStructure } catch { }
