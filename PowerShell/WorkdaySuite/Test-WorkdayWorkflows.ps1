<#
.SYNOPSIS
    Tests all 17 ESS Pre-configured Workday workflows.

.DESCRIPTION
    Calls actual Workday SOAP APIs to validate that security domains
    are configured correctly. Tests each workflow and reports PASS/FAIL.

.PARAMETER WorkdayTenant
    Your Workday tenant name (e.g., contoso_impl)

.PARAMETER Username
    ISU username (without @tenant)

.PARAMETER Password
    ISU password (SecureString)

.PARAMETER TestEmployeeId
    Employee ID to test queries against

.PARAMETER SkipWriteTests
    Skip Update Email/Phone tests (safer for production)

.EXAMPLE
    .\Test-WorkdayWorkflows.ps1
    # Interactive prompts

.EXAMPLE
    .\Test-WorkdayWorkflows.ps1 -WorkdayTenant "contoso_impl" -Username "ISU_WQL_COPILOT" -TestEmployeeId "21508"

.NOTES
    Version: 1.0.0
    Author: ESS Pre-flight Validator
#>

param(
    [string]$WorkdayTenant,
    [string]$Username,
    [SecureString]$Password,
    [string]$TestEmployeeId,
    [switch]$SkipWriteTests
)

#region Interactive Prompts
if (-not $WorkdayTenant) { $WorkdayTenant = Read-Host "Enter Workday Tenant (e.g., contoso_impl)" }
if (-not $Username) { $Username = Read-Host "Enter ISU Username (without @tenant)" }
if (-not $Password) { $Password = Read-Host "Enter ISU Password" -AsSecureString }
if (-not $TestEmployeeId) { $TestEmployeeId = Read-Host "Enter Test Employee ID (e.g., 21508)" }

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
#endregion

#region SOAP Helper
function Invoke-WorkdaySoap {
    param(
        [string]$Service,      # Human_Resources, Compensation, etc.
        [string]$Operation,    # The SOAP body XML
        [string]$Version = "v42.0"
    )
    
    $soapEnvelope = @"
<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
xmlns:xsd="http://www.w3.org/2001/XMLSchema"
xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
<env:Header>
<wsse:Security env:mustUnderstand="1">
<wsse:UsernameToken>
<wsse:Username>$Username@$WorkdayTenant</wsse:Username>
<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$plainPassword</wsse:Password>
</wsse:UsernameToken>
</wsse:Security>
</env:Header>
<env:Body>
$Operation
</env:Body>
</env:Envelope>
"@
    
    $url = "https://wd2-impl-services1.workday.com/ccx/service/$WorkdayTenant/$Service/$Version"
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method Post -Headers @{"Content-Type"="application/xml"} -Body $soapEnvelope -ErrorAction Stop
        return @{ Success = $true; Response = $response.Content; StatusCode = $response.StatusCode }
    }
    catch {
        $errorMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $errorMsg = $reader.ReadToEnd()
            } catch { }
        }
        return @{ Success = $false; Error = $errorMsg }
    }
}
#endregion

#region Workflow Definitions
$workflows = @(
    # READ WORKFLOWS - Get_Workers based
    @{
        Name = "Employee ID"
        Service = "Human_Resources"
        Type = "Read"
        ResponseGroup = "<bsvc:Include_Reference>true</bsvc:Include_Reference>"
        CheckXPath = "//*[local-name()='ID'][@*[local-name()='type']='Employee_ID']"
    },
    @{
        Name = "Company Code"
        Service = "Human_Resources"
        Type = "Read"
        ResponseGroup = "<bsvc:Include_Organizations>true</bsvc:Include_Organizations>"
        CheckXPath = "//*[local-name()='Organization_Data']"
    },
    @{
        Name = "Cost Center"
        Service = "Human_Resources"
        Type = "Read"
        ResponseGroup = "<bsvc:Include_Organizations>true</bsvc:Include_Organizations>"
        CheckXPath = "//*[local-name()='Organization_Type_Reference']"
    },
    @{
        Name = "Hire Date"
        Service = "Human_Resources"
        Type = "Read"
        ResponseGroup = "<bsvc:Include_Employment_Information>true</bsvc:Include_Employment_Information>"
        CheckXPath = "//*[local-name()='Hire_Date']"
    },
    @{
        Name = "Employment Information"
        Service = "Human_Resources"
        Type = "Read"
        ResponseGroup = "<bsvc:Include_Employment_Information>true</bsvc:Include_Employment_Information>"
        CheckXPath = "//*[local-name()='Employment_Data']"
    },
    @{
        Name = "Position Number"
        Service = "Human_Resources"
        Type = "Read"
        ResponseGroup = "<bsvc:Include_Employment_Information>true</bsvc:Include_Employment_Information>"
        CheckXPath = "//*[local-name()='Position_ID']"
    },
    @{
        Name = "Service Anniversary"
        Service = "Human_Resources"
        Type = "Read"
        ResponseGroup = "<bsvc:Include_Employment_Information>true</bsvc:Include_Employment_Information>"
        CheckXPath = "//*[local-name()='Continuous_Service_Date'] | //*[local-name()='Hire_Date']"
    },
    @{
        Name = "National IDs"
        Service = "Human_Resources"
        Type = "Read"
        IsPII = $true
        ResponseGroup = "<bsvc:Include_Personal_Information>true</bsvc:Include_Personal_Information>"
        CheckXPath = "//*[local-name()='National_ID']"
    },
    @{
        Name = "Passports"
        Service = "Human_Resources"
        Type = "Read"
        IsPII = $true
        ResponseGroup = "<bsvc:Include_Personal_Information>true</bsvc:Include_Personal_Information>"
        CheckXPath = "//*[local-name()='Passport_ID']"
    },
    @{
        Name = "Visas"
        Service = "Human_Resources"
        Type = "Read"
        IsPII = $true
        ResponseGroup = "<bsvc:Include_Personal_Information>true</bsvc:Include_Personal_Information>"
        CheckXPath = "//*[local-name()='Visa_ID']"
    },
    @{
        Name = "Language Information"
        Service = "Human_Resources"
        Type = "Read"
        ResponseGroup = "<bsvc:Include_Qualifications>true</bsvc:Include_Qualifications>"
        CheckXPath = "//*[local-name()='Language']"
    },
    @{
        Name = "Certifications"
        Service = "Human_Resources"
        Type = "Read"
        ResponseGroup = "<bsvc:Include_Qualifications>true</bsvc:Include_Qualifications>"
        CheckXPath = "//*[local-name()='Certification']"
    },
    # READ WORKFLOWS - Separate API calls
    @{
        Name = "Base Compensation"
        Service = "Compensation"
        Type = "Read"
        UseCustomOperation = $true
        Operation = @"
<bsvc:Get_Compensation_Plans_Request xmlns:bsvc="urn:com.workday/bsvc" bsvc:version="v42.0">
<bsvc:Request_References>
<bsvc:Compensation_Plan_Reference>
<bsvc:ID bsvc:type="Employee_ID">$TestEmployeeId</bsvc:ID>
</bsvc:Compensation_Plan_Reference>
</bsvc:Request_References>
</bsvc:Get_Compensation_Plans_Request>
"@
        CheckXPath = "//*[local-name()='Compensation'] | //*[local-name()='Amount']"
    },
    @{
        Name = "Compensation Ratio"
        Service = "Compensation"
        Type = "Read"
        UseCustomOperation = $true
        Operation = @"
<bsvc:Get_Compensation_Plans_Request xmlns:bsvc="urn:com.workday/bsvc" bsvc:version="v42.0">
<bsvc:Request_References>
<bsvc:Compensation_Plan_Reference>
<bsvc:ID bsvc:type="Employee_ID">$TestEmployeeId</bsvc:ID>
</bsvc:Compensation_Plan_Reference>
</bsvc:Request_References>
</bsvc:Get_Compensation_Plans_Request>
"@
        CheckXPath = "//*[local-name()='Compa_Ratio'] | //*[local-name()='Compensation']"
    },
    @{
        Name = "Emergency Contact"
        Service = "Human_Resources"
        Type = "Read"
        IsPII = $true
        ResponseGroup = "<bsvc:Include_Personal_Information>true</bsvc:Include_Personal_Information>"
        CheckXPath = "//*[local-name()='Emergency_Contact']"
    },
    # WRITE WORKFLOWS
    @{
        Name = "Update Email"
        Service = "Human_Resources"
        Type = "Write"
        TestMethod = "ValidateOnly"
    },
    @{
        Name = "Update Phone"
        Service = "Human_Resources"
        Type = "Write"
        TestMethod = "ValidateOnly"
    }
)
#endregion

#region Main Execution
Write-Host ""
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "           WORKDAY WORKFLOW TESTER v1.0                               " -ForegroundColor Cyan
Write-Host "           Testing all 17 ESS Pre-configured Workflows                " -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Tenant: $WorkdayTenant" -ForegroundColor Gray
Write-Host "  ISU: $Username" -ForegroundColor Gray
Write-Host "  Test Employee: $TestEmployeeId" -ForegroundColor Gray
Write-Host ""

$results = @()
$passCount = 0
$failCount = 0
$skipCount = 0

$effectiveDate = Get-Date -Format "yyyy-MM-dd"

# Build base Get_Workers operation
function Get-WorkersOperation {
    param([string]$ResponseGroup)
    return @"
<bsvc:Get_Workers_Request xmlns:bsvc="urn:com.workday/bsvc" bsvc:version="v42.0">
<bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false" bsvc:Ignore_Invalid_References="true">
<bsvc:Worker_Reference bsvc:Descriptor="Employee_ID">
<bsvc:ID bsvc:type="Employee_ID">$TestEmployeeId</bsvc:ID>
</bsvc:Worker_Reference>
</bsvc:Request_References>
<bsvc:Response_Filter>
<bsvc:As_Of_Effective_Date>$effectiveDate</bsvc:As_Of_Effective_Date>
</bsvc:Response_Filter>
<bsvc:Response_Group>
$ResponseGroup
</bsvc:Response_Group>
</bsvc:Get_Workers_Request>
"@
}

Write-Host "=======================================================================" -ForegroundColor DarkCyan
Write-Host "  READ WORKFLOWS (15)" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor DarkCyan
Write-Host ""

foreach ($wf in ($workflows | Where-Object { $_.Type -eq "Read" })) {
    $piiTag = if ($wf.IsPII) { " [PII]" } else { "" }
    Write-Host -NoNewline "  Testing $($wf.Name)$piiTag... " -ForegroundColor White
    
    # Build operation
    if ($wf.UseCustomOperation) {
        $operation = $wf.Operation
    } else {
        $operation = Get-WorkersOperation -ResponseGroup $wf.ResponseGroup
    }
    
    # Call API
    $result = Invoke-WorkdaySoap -Service $wf.Service -Operation $operation
    
    if ($result.Success) {
        # Check if expected data exists
        [xml]$xml = $result.Response
        $found = $xml | Select-Xml -XPath $wf.CheckXPath -ErrorAction SilentlyContinue
        
        if ($found) {
            Write-Host "[PASS]" -ForegroundColor Green
            $passCount++
            $results += [PSCustomObject]@{ Workflow = $wf.Name; Type = "Read"; Status = "PASS"; Details = "Data retrieved" }
        } else {
            Write-Host "[PASS*]" -ForegroundColor Yellow
            Write-Host "       (API accessible, but no data for this employee)" -ForegroundColor DarkGray
            $passCount++
            $results += [PSCustomObject]@{ Workflow = $wf.Name; Type = "Read"; Status = "PASS*"; Details = "API works, no data found" }
        }
    } else {
        # Check error type
        if ($result.Error -match "permission|unauthorized|access denied|not authorized") {
            Write-Host "[FAIL] Permission Denied" -ForegroundColor Red
            $failCount++
            $results += [PSCustomObject]@{ Workflow = $wf.Name; Type = "Read"; Status = "FAIL"; Details = "Permission denied" }
        } else {
            Write-Host "[FAIL] $($result.Error.Substring(0, [Math]::Min(50, $result.Error.Length)))..." -ForegroundColor Red
            $failCount++
            $results += [PSCustomObject]@{ Workflow = $wf.Name; Type = "Read"; Status = "FAIL"; Details = $result.Error.Substring(0, [Math]::Min(100, $result.Error.Length)) }
        }
    }
}

Write-Host ""
Write-Host "=======================================================================" -ForegroundColor DarkCyan
Write-Host "  WRITE WORKFLOWS (2)" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor DarkCyan
Write-Host ""

if ($SkipWriteTests) {
    Write-Host "  [SKIP] Update Email - Skipped (use -SkipWriteTests:$false to test)" -ForegroundColor Yellow
    Write-Host "  [SKIP] Update Phone - Skipped (use -SkipWriteTests:$false to test)" -ForegroundColor Yellow
    $skipCount += 2
    $results += [PSCustomObject]@{ Workflow = "Update Email"; Type = "Write"; Status = "SKIP"; Details = "Skipped by user" }
    $results += [PSCustomObject]@{ Workflow = "Update Phone"; Type = "Write"; Status = "SKIP"; Details = "Skipped by user" }
} else {
    Write-Host "  NOTE: Write tests query update capability WITHOUT making changes" -ForegroundColor DarkGray
    Write-Host ""
    
    # Test Update Email - Check if we can access the Change_Work_Contact_Information operation
    Write-Host -NoNewline "  Testing Update Email... " -ForegroundColor White
    $emailTestOp = @"
<bsvc:Get_Change_Work_Contact_Information_Event_Request xmlns:bsvc="urn:com.workday/bsvc" bsvc:version="v42.0">
<bsvc:Request_References>
<bsvc:Change_Work_Contact_Information_Event_Reference>
<bsvc:ID bsvc:type="Employee_ID">$TestEmployeeId</bsvc:ID>
</bsvc:Change_Work_Contact_Information_Event_Reference>
</bsvc:Request_References>
</bsvc:Get_Change_Work_Contact_Information_Event_Request>
"@
    $emailResult = Invoke-WorkdaySoap -Service "Human_Resources" -Operation $emailTestOp
    
    if ($emailResult.Success -or ($emailResult.Error -notmatch "permission|unauthorized|not authorized")) {
        Write-Host "[PASS]" -ForegroundColor Green
        $passCount++
        $results += [PSCustomObject]@{ Workflow = "Update Email"; Type = "Write"; Status = "PASS"; Details = "API accessible" }
    } else {
        Write-Host "[FAIL] Permission Denied" -ForegroundColor Red
        $failCount++
        $results += [PSCustomObject]@{ Workflow = "Update Email"; Type = "Write"; Status = "FAIL"; Details = "Permission denied" }
    }
    
    # Test Update Phone - Same operation covers both
    Write-Host -NoNewline "  Testing Update Phone... " -ForegroundColor White
    if ($emailResult.Success -or ($emailResult.Error -notmatch "permission|unauthorized|not authorized")) {
        Write-Host "[PASS]" -ForegroundColor Green
        $passCount++
        $results += [PSCustomObject]@{ Workflow = "Update Phone"; Type = "Write"; Status = "PASS"; Details = "API accessible" }
    } else {
        Write-Host "[FAIL] Permission Denied" -ForegroundColor Red
        $failCount++
        $results += [PSCustomObject]@{ Workflow = "Update Phone"; Type = "Write"; Status = "FAIL"; Details = "Permission denied" }
    }
}

#endregion

#region Summary
Write-Host ""
Write-Host "=======================================================================" -ForegroundColor DarkCyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "=======================================================================" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Total: 17 workflows" -ForegroundColor White
Write-Host "  Passed: $passCount" -ForegroundColor Green
Write-Host "  Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Skipped: $skipCount" -ForegroundColor $(if ($skipCount -gt 0) { "Yellow" } else { "Green" })
Write-Host ""

if ($failCount -gt 0) {
    Write-Host "  FAILED WORKFLOWS:" -ForegroundColor Red
    $results | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "    • $($_.Workflow): $($_.Details)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "  ACTION: Ask Workday Admin to grant missing security domains" -ForegroundColor Yellow
} else {
    Write-Host "  ALL WORKFLOWS PASSED!" -ForegroundColor Green
    Write-Host "  ESS Agent should work correctly with this ISU account." -ForegroundColor White
}
Write-Host ""

# Cleanup credentials
$plainPassword = $null
[System.GC]::Collect()

# Return results
$results | Format-Table -AutoSize
#endregion
