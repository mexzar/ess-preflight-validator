<#
.SYNOPSIS
    Tests Workday SSO connectivity for end users via Azure AD OAuth
.DESCRIPTION
    Validates that end users can authenticate to Workday via Azure AD SSO and 
    access their own employee data using delegated permissions. This simulates
    the ESS agent calling Workday on behalf of a logged-in user.
.EXAMPLE
    .\Test-WorkdaySSOConnectivity.ps1
    Prompts for tenant, Azure AD app, and test user, then validates SSO flow
.NOTES
    Requires: Azure AD Enterprise App configured for Workday with OAuth
    Author: ESS Pre-flight Validator
    Version: 1.0.0
#>

[CmdletBinding()]
param()

#Requires -Version 7.0

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Workday SSO Connectivity Test (Azure AD OAuth)            ║" -ForegroundColor Cyan
Write-Host "║     Tests end-user delegated access via SSO                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Collect inputs
$workdayTenant = Read-Host "Enter Workday Tenant (e.g., contoso_impl)"
$azureAppId = Read-Host "Enter Azure AD App ID (Workday Enterprise App Client ID)"
$testUserUPN = Read-Host "Enter test user UPN (e.g., user@contoso.com)"
$tenantId = Read-Host "Enter Azure AD Tenant ID (or press Enter to use 'organizations')"
$workdayBaseUrl = Read-Host "Enter Workday base URL (or press Enter for default: https://wd2-impl-services1.workday.com)"

if ([string]::IsNullOrWhiteSpace($tenantId)) {
    $tenantId = "organizations"
}

if ([string]::IsNullOrWhiteSpace($workdayBaseUrl)) {
    $workdayBaseUrl = "https://wd2-impl-services1.workday.com"
}

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Configuration Summary" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Workday Tenant: $workdayTenant" -ForegroundColor Gray
Write-Host "Workday Base URL: $workdayBaseUrl" -ForegroundColor Gray
Write-Host "Azure AD App: $azureAppId" -ForegroundColor Gray
Write-Host "Test User: $testUserUPN" -ForegroundColor Gray
Write-Host "Azure AD Tenant: $tenantId" -ForegroundColor Gray
Write-Host ""

# Step 1: Initiate Device Code Flow
Write-Host "🔐 Step 1: Initiating Azure AD authentication..." -ForegroundColor Cyan
Write-Host "   User will authenticate as: $testUserUPN" -ForegroundColor Gray
Write-Host ""

$workdayScope = "$workdayBaseUrl/.default"
$deviceCodeUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/devicecode"
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

try {
    $deviceCodeBody = @{
        client_id = $azureAppId
        scope = $workdayScope
    }
    
    $deviceCodeResponse = Invoke-RestMethod -Uri $deviceCodeUrl -Method Post -Body $deviceCodeBody -ErrorAction Stop
    
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "   USER AUTHENTICATION REQUIRED" -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "1. Open a browser and navigate to:" -ForegroundColor White
    Write-Host "   $($deviceCodeResponse.verification_uri)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "2. Enter this code:" -ForegroundColor White
    Write-Host "   $($deviceCodeResponse.user_code)" -ForegroundColor Yellow -BackgroundColor Black
    Write-Host ""
    Write-Host "3. Sign in as: $testUserUPN" -ForegroundColor White
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "⏳ Waiting for authentication (timeout in $($deviceCodeResponse.expires_in) seconds)..." -ForegroundColor Gray
    Write-Host ""
}
catch {
    Write-Host "❌ Failed to initiate device code flow" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 2: Poll for Token
$tokenResponse = $null
$timeout = [DateTime]::Now.AddSeconds($deviceCodeResponse.expires_in)
$attempts = 0

while ([DateTime]::Now -lt $timeout -and !$tokenResponse) {
    Start-Sleep -Seconds 5
    $attempts++
    
    try {
        $tokenBody = @{
            client_id = $azureAppId
            grant_type = "urn:ietf:params:oauth:grant-type:device_code"
            device_code = $deviceCodeResponse.device_code
        }
        
        $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $tokenBody -ErrorAction Stop
    }
    catch {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
        
        if ($errorDetails.error -eq "authorization_pending") {
            # User hasn't authenticated yet - continue polling
            Write-Host "." -NoNewline -ForegroundColor Gray
        }
        elseif ($errorDetails.error -eq "authorization_declined") {
            Write-Host ""
            Write-Host "❌ User declined authorization" -ForegroundColor Red
            exit 1
        }
        elseif ($errorDetails.error -eq "expired_token") {
            Write-Host ""
            Write-Host "❌ Device code expired - user took too long to authenticate" -ForegroundColor Red
            exit 1
        }
        else {
            Write-Host ""
            Write-Host "❌ Authentication error: $($errorDetails.error_description)" -ForegroundColor Red
            exit 1
        }
    }
}

Write-Host ""

if (!$tokenResponse) {
    Write-Host "❌ Authentication timeout - user did not complete sign-in" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Authentication successful!" -ForegroundColor Green
Write-Host "   Token acquired for: $testUserUPN" -ForegroundColor Gray
Write-Host ""

$accessToken = $tokenResponse.access_token

# Step 3: Build OAuth-authenticated SOAP request
Write-Host "🔍 Step 2: Testing Workday API access..." -ForegroundColor Cyan
Write-Host ""

$soapRequest = @"
<?xml version="1.0" encoding="UTF-8"?>
<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<env:Header>
<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" env:mustUnderstand="1">
<wsse:BinarySecurityToken 
    ValueType="http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0"
    EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary">$accessToken</wsse:BinarySecurityToken>
</wsse:Security>
</env:Header>
<env:Body>
<bsvc:Get_Workers_Request xmlns:bsvc="urn:com.workday/bsvc" bsvc:version="v42.0">
<bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false" bsvc:Ignore_Invalid_References="true">
<bsvc:Worker_Reference>
<bsvc:ID bsvc:type="UPN">$testUserUPN</bsvc:ID>
</bsvc:Worker_Reference>
</bsvc:Request_References>
<bsvc:Response_Filter>
<bsvc:As_Of_Effective_Date>$(Get-Date -Format 'yyyy-MM-dd')</bsvc:As_Of_Effective_Date>
</bsvc:Response_Filter>
<bsvc:Response_Group>
<bsvc:Include_Personal_Information>true</bsvc:Include_Personal_Information>
<bsvc:Include_Employment_Information>true</bsvc:Include_Employment_Information>
<bsvc:Include_Organizations>true</bsvc:Include_Organizations>
<bsvc:Include_Reference>true</bsvc:Include_Reference>
</bsvc:Response_Group>
</bsvc:Get_Workers_Request>
</env:Body>
</env:Envelope>
"@

$workdayUrl = "$workdayBaseUrl/ccx/service/$workdayTenant/Human_Resources/v42.0"

$headers = @{
    "Content-Type" = "application/xml"
    "Authorization" = "Bearer $accessToken"
}

Write-Host "Target: $workdayUrl" -ForegroundColor Gray
Write-Host "Method: OAuth Bearer Token (SSO)" -ForegroundColor Gray
Write-Host "User: $testUserUPN" -ForegroundColor Gray
Write-Host ""

try {
    $response = Invoke-WebRequest -Uri $workdayUrl -Method Post -Headers $headers -Body $soapRequest -ErrorAction Stop
    
    [xml]$xmlResponse = $response.Content
    
    # Parse response
    $employeeIdResult = $xmlResponse | Select-Xml -XPath "//*[local-name()='ID'][@*[local-name()='type']='Employee_ID']" | Select-Object -ExpandProperty Node -First 1
    $firstName = $xmlResponse | Select-Xml -XPath "//*[local-name()='First_Name']" | Select-Object -ExpandProperty Node -First 1
    $lastName = $xmlResponse | Select-Xml -XPath "//*[local-name()='Last_Name']" | Select-Object -ExpandProperty Node -First 1
    $email = $xmlResponse | Select-Xml -XPath "//*[local-name()='Email_Address']" | Select-Object -ExpandProperty Node -First 1
    $jobTitle = $xmlResponse | Select-Xml -XPath "//*[local-name()='Business_Title']" | Select-Object -ExpandProperty Node -First 1
    
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "   ✅ WORKDAY SSO CONNECTIVITY: SUCCESS" -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "Employee Information Retrieved via SSO" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Employee ID: $($employeeIdResult.'#text')"
    Write-Host "First Name: $($firstName.'#text')"
    Write-Host "Last Name: $($lastName.'#text')"
    Write-Host "Email: $($email.'#text')"
    Write-Host "Job Title: $($jobTitle.'#text')"
    Write-Host "UPN: $testUserUPN"
    Write-Host ""
    Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Retrieved: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC')"
    Write-Host ""
    Write-Host "✅ Delegated Access Validated" -ForegroundColor Green
    Write-Host "   • User successfully authenticated via Azure AD" -ForegroundColor Gray
    Write-Host "   • OAuth token acquired and accepted by Workday" -ForegroundColor Gray
    Write-Host "   • User can access their own employee data" -ForegroundColor Gray
    Write-Host "   • SSO flow working end-to-end" -ForegroundColor Gray
    Write-Host ""
    
    # Clear sensitive data
    $accessToken = $null
    [System.GC]::Collect()
    
    exit 0
}
catch {
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host "   ❌ WORKDAY SSO CONNECTIVITY: FAILED" -ForegroundColor Red
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    
    if ($_.Exception.Response) {
        try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Host "Workday Response:" -ForegroundColor Yellow
            Write-Host $responseBody -ForegroundColor Red
            Write-Host ""
        }
        catch {
            Write-Host "Could not read response details" -ForegroundColor Gray
            Write-Host ""
        }
    }
    
    Write-Host "Common Issues:" -ForegroundColor Yellow
    Write-Host "• Azure AD Enterprise App not configured for Workday" -ForegroundColor Gray
    Write-Host "• Workday OAuth not enabled on tenant" -ForegroundColor Gray
    Write-Host "• User not assigned to Workday enterprise app in Azure AD" -ForegroundColor Gray
    Write-Host "• API permissions not granted (delegated User.Read scope)" -ForegroundColor Gray
    Write-Host "• Token claims not mapped correctly in Workday" -ForegroundColor Gray
    Write-Host "• Workday security group membership missing for user" -ForegroundColor Gray
    Write-Host "• OAuth client not authorized in Workday API settings" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Troubleshooting Steps:" -ForegroundColor Yellow
    Write-Host "1. Verify Azure AD app registration exists for Workday" -ForegroundColor Gray
    Write-Host "2. Check user is assigned to Workday enterprise app" -ForegroundColor Gray
    Write-Host "3. Confirm Workday OAuth client is configured and active" -ForegroundColor Gray
    Write-Host "4. Validate API permissions include Workday access" -ForegroundColor Gray
    Write-Host "5. Test user can access Workday web UI via SSO first" -ForegroundColor Gray
    Write-Host ""
    
    # Clear sensitive data
    $accessToken = $null
    [System.GC]::Collect()
    
    exit 1
}
