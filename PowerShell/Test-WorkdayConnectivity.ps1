# Test Workday Connectivity Script (SOAP with WS-Security)
$workdayTenant = Read-Host "Enter Workday Tenant (e.g., contoso_impl)"
$username = Read-Host "Enter Workday Username (without @tenant)"
$password = Read-Host "Enter Workday Password" -AsSecureString
$employeeId = Read-Host "Enter Employee ID to test (e.g., 21508)"
$effectiveDate = Read-Host "Enter Effective Date (YYYY-MM-DD) or press Enter for today"

if ([string]::IsNullOrWhiteSpace($effectiveDate)) {
    $effectiveDate = Get-Date -Format "yyyy-MM-dd"
}

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Build full SOAP envelope with WS-Security (Bruno format)
$soapRequest = @"
<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
xmlns:xsd="http://www.w3.org/2001/XMLSchema"
xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">
<env:Header>
<wsse:Security env:mustUnderstand="1">
<wsse:UsernameToken>
<wsse:Username>$username@$workdayTenant</wsse:Username>
<wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">$plainPassword</wsse:Password>
</wsse:UsernameToken>
</wsse:Security>
</env:Header>
<env:Body>
<bsvc:Get_Workers_Request xmlns:bsvc="urn:com.workday/bsvc" bsvc:version="v42.0">
<bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false" bsvc:Ignore_Invalid_References="true">
<bsvc:Worker_Reference bsvc:Descriptor="Employee_ID">
<bsvc:ID bsvc:type="Employee_ID">$employeeId</bsvc:ID>
</bsvc:Worker_Reference>
</bsvc:Request_References>
<bsvc:Response_Filter>
<bsvc:As_Of_Effective_Date>$effectiveDate</bsvc:As_Of_Effective_Date>
</bsvc:Response_Filter>
<bsvc:Response_Group>
<bsvc:Include_Personal_Information>true</bsvc:Include_Personal_Information>
<bsvc:Include_Employment_Information>true</bsvc:Include_Employment_Information>
<bsvc:Include_Organizations>true</bsvc:Include_Organizations>
<bsvc:Include_Reference>true</bsvc:Include_Reference>
<bsvc:Include_Roles>true</bsvc:Include_Roles>
</bsvc:Response_Group>
</bsvc:Get_Workers_Request>
</env:Body>
</env:Envelope>
"@

$workdayUrl = "https://wd2-impl-services1.workday.com/ccx/service/$workdayTenant/Human_Resources/v42.0"

$headers = @{
    "Content-Type" = "application/xml"
}

Write-Host "`n🔍 Testing Workday Connectivity..." -ForegroundColor Cyan
Write-Host "Tenant: $workdayTenant" -ForegroundColor Gray
Write-Host "Username: $username@$workdayTenant" -ForegroundColor Gray
Write-Host "Employee ID: $employeeId" -ForegroundColor Gray
Write-Host "Effective Date: $effectiveDate" -ForegroundColor Gray
Write-Host "URL: $workdayUrl" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri $workdayUrl -Method Post -Headers $headers -Body $soapRequest -ErrorAction Stop
    
    Write-Host "✅ Workday Connectivity: SUCCESS (HTTP $($response.StatusCode))" -ForegroundColor Green
    Write-Host ""
    
    [xml]$xmlResponse = $response.Content
    
    $employeeIdResult = $xmlResponse | Select-Xml -XPath "//*[local-name()='ID'][@*[local-name()='type']='Employee_ID']" | Select-Object -ExpandProperty Node -First 1
    $firstName = $xmlResponse | Select-Xml -XPath "//*[local-name()='First_Name']" | Select-Object -ExpandProperty Node -First 1
    $lastName = $xmlResponse | Select-Xml -XPath "//*[local-name()='Last_Name']" | Select-Object -ExpandProperty Node -First 1
    $email = $xmlResponse | Select-Xml -XPath "//*[local-name()='Email_Address']" | Select-Object -ExpandProperty Node -First 1
    $jobTitle = $xmlResponse | Select-Xml -XPath "//*[local-name()='Business_Title']" | Select-Object -ExpandProperty Node -First 1
    
    Write-Host "✅ Workday Connectivity: SUCCESS" -ForegroundColor Green
    Write-Host ""
    Write-Host "Employee Information" -ForegroundColor Cyan
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host "Employee ID: $($employeeIdResult.'#text')"
    Write-Host "First Name: $($firstName.'#text')"
    Write-Host "Last Name: $($lastName.'#text')"
    Write-Host "Email: $($email.'#text')"
    Write-Host "Job Title: $($jobTitle.'#text')"
    Write-Host ""
    Write-Host "==================" -ForegroundColor Cyan
    Write-Host "Retrieved: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
    
    $plainPassword = $null
    [System.GC]::Collect()
}
catch {
    Write-Host "❌ Workday Connectivity: FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host ""
            Write-Host "Workday Response:" -ForegroundColor Yellow
            Write-Host $responseBody -ForegroundColor Red
        }
        catch {
            Write-Host "Could not read response body" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "Common Issues:" -ForegroundColor Yellow
    Write-Host "• Username format: Use 'username' only (not 'username@tenant')" -ForegroundColor Gray
    Write-Host "• Tenant name: Check if it needs '_impl' suffix" -ForegroundColor Gray
    Write-Host "• Employee ID doesn't exist in tenant" -ForegroundColor Gray
    Write-Host "• User lacks 'Get Workers' permission in Workday" -ForegroundColor Gray
    Write-Host "• Network/firewall blocking connection" -ForegroundColor Gray
    
    $plainPassword = $null
    [System.GC]::Collect()
}
