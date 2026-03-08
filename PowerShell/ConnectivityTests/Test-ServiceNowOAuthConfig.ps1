<#
.SYNOPSIS
    Deep OAuth/OIDC diagnostics for a ServiceNow instance

.DESCRIPTION
    Performs Diagnosis-stage root cause analysis of OAuth and OIDC configuration
    on a ServiceNow instance. This script is intended for use when E2E connectivity
    tests fail and the operator needs to understand why OAuth-based authentication
    is not working.

    Checks include:
      SN-OAUTH-001  OAuth entity (provider) configuration
      SN-OAUTH-002  OIDC Provider configuration
      SN-OAUTH-003  Redirect URL validation for Power Platform
      SN-OAUTH-004  Token lifespan thresholds
      SN-OAUTH-005  User claim mapping (email / sub)
      SN-OAUTH-006  OAuth application scope for ESS integration

.PARAMETER Instance
    ServiceNow instance name (e.g., "contoso" for contoso.service-now.com)

.PARAMETER Username
    ServiceNow username for Basic authentication

.PARAMETER Password
    ServiceNow password for Basic authentication

.PARAMETER OAuthToken
    OAuth access token (alternative to username/password)

.PARAMETER EnvironmentId
    Optional Power Platform environment ID for context in diagnostics

.EXAMPLE
    .\Test-ServiceNowOAuthConfig.ps1 -Instance "contoso" -Username "admin" -Password "P@ssw0rd"

.EXAMPLE
    .\Test-ServiceNowOAuthConfig.ps1 -Instance "contoso" -OAuthToken "eyJ0eXAi..."

.EXAMPLE
    $results = Test-ServiceNowOAuthConfig -Instance "contoso" -Username "admin" -Password "P@ss" -EnvironmentId "env-abc-123"
    $results | Where-Object Status -eq 'Failed'
#>

function Test-ServiceNowOAuthConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Instance,

        [Parameter(Mandatory=$false)]
        [string]$Username,

        [Parameter(Mandatory=$false)]
        [string]$Password,

        [Parameter(Mandatory=$false)]
        [string]$OAuthToken,

        [Parameter(Mandatory=$false)]
        [string]$EnvironmentId
    )

    # ── Documentation link shared across all checkpoints ─────────────────
    $docLink = 'https://learn.microsoft.com/en-us/power-platform/admin/connect-servicenow'

    # ── Results accumulator ──────────────────────────────────────────────
    $results = @()

    # ── Helper: console output ───────────────────────────────────────────
    function Write-DiagStep {
        param(
            [string]$Message,
            [string]$Status = 'Info'
        )
        $color = switch ($Status) {
            'Success' { 'Green'  }
            'Error'   { 'Red'    }
            'Warning' { 'Yellow' }
            default   { 'Cyan'   }
        }
        $icon = switch ($Status) {
            'Success' { '✓' }
            'Error'   { '✗' }
            'Warning' { '⚠' }
            default   { '→' }
        }
        Write-Host "$icon $Message" -ForegroundColor $color
    }

    # ── Helper: call ServiceNow REST API ─────────────────────────────────
    function Invoke-SNApi {
        param(
            [string]$BaseUrl,
            [hashtable]$Headers,
            [string]$Endpoint
        )
        $uri = "$BaseUrl/$Endpoint"
        try {
            $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $Headers -ContentType 'application/json'
            return @{ Success = $true; Data = $response; StatusCode = 200 }
        }
        catch {
            $statusCode = $null
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }
            return @{ Success = $false; Error = $_.Exception.Message; StatusCode = $statusCode }
        }
    }

    # ── Banner ───────────────────────────────────────────────────────────
    Write-Host "`n╔═══════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       ServiceNow OAuth / OIDC Deep Diagnostics  (Diagnosis Stage)    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

    # ── Gather credentials interactively if not supplied ──────────────────
    if (-not $Instance) {
        $Instance = Read-Host "ServiceNow Instance (e.g., 'contoso' for contoso.service-now.com)"
    }

    if (-not $OAuthToken) {
        if (-not $Username) {
            $Username = Read-Host 'ServiceNow Username'
        }
        if (-not $Password) {
            $securePassword = Read-Host 'ServiceNow Password' -AsSecureString
            $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
            )
        }
    }

    # ── Build base URL & auth headers ────────────────────────────────────
    $baseUrl = "https://$Instance.service-now.com/api/now"

    if ($OAuthToken) {
        $headers = @{
            'Authorization' = "Bearer $OAuthToken"
            'Accept'        = 'application/json'
        }
        Write-DiagStep 'Using OAuth Bearer authentication' -Status 'Info'
    }
    else {
        $base64Auth = [Convert]::ToBase64String(
            [Text.Encoding]::ASCII.GetBytes("$($Username):$($Password)")
        )
        $headers = @{
            'Authorization' = "Basic $base64Auth"
            'Accept'        = 'application/json'
        }
        Write-DiagStep "Using Basic authentication with username: $Username" -Status 'Info'
    }

    if ($EnvironmentId) {
        Write-DiagStep "Environment ID: $EnvironmentId" -Status 'Info'
    }

    Write-Host ''

    # ── Shared 403 handling helper ───────────────────────────────────────
    $adminRemediation = 'Run this script with a ServiceNow admin account, or verify OAuth settings manually in ServiceNow Admin > OAuth > Application Registry'

    # ══════════════════════════════════════════════════════════════════════
    # SN-OAUTH-001 — OAuth Entity Configuration
    # ══════════════════════════════════════════════════════════════════════
    Write-DiagStep 'SN-OAUTH-001: Querying OAuth entities (oauth_entity)...' -Status 'Info'

    $oauthEntities = $null
    $oauthEntityResult = Invoke-SNApi -BaseUrl $baseUrl -Headers $headers -Endpoint 'table/oauth_entity?sysparm_limit=10'

    if ($oauthEntityResult.Success) {
        $oauthEntities = $oauthEntityResult.Data.result
        $count = @($oauthEntities).Count

        if ($count -gt 0) {
            Write-DiagStep "  Found $count OAuth provider(s)" -Status 'Success'
            foreach ($entity in $oauthEntities) {
                Write-DiagStep "    • $($entity.name)  (type: $($entity.type))" -Status 'Info'
            }
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-001'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Passed'
                Result            = "Found $count OAuth entity record(s) configured"
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = ''
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
        }
        else {
            Write-DiagStep '  No OAuth entities found' -Status 'Error'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-001'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Failed'
                Result            = 'No OAuth entity records found in ServiceNow'
                Remediation       = 'Create an OAuth Application Registry entry in ServiceNow: System OAuth > Application Registry > New. Configure it for the Power Platform connector.'
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = 'OAuth Application Registry is empty — no provider configured for external consumers'
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
        }
    }
    else {
        if ($oauthEntityResult.StatusCode -eq 403) {
            Write-DiagStep '  403 Forbidden — admin role required to read oauth_entity' -Status 'Warning'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-001'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Warning'
                Result            = 'Admin access required for OAuth diagnostics'
                Remediation       = $adminRemediation
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = 'Current credentials lack admin role; oauth_entity table returned 403'
                Confidence        = 'Medium'
                GatingSignal      = 'Yes'
            }
        }
        else {
            Write-DiagStep "  Failed: $($oauthEntityResult.Error)" -Status 'Error'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-001'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Failed'
                Result            = "Error querying oauth_entity: $($oauthEntityResult.Error)"
                Remediation       = 'Verify ServiceNow connectivity and credentials, then retry.'
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = "REST call to oauth_entity failed: $($oauthEntityResult.Error)"
                Confidence        = 'Medium'
                GatingSignal      = 'Yes'
            }
        }
    }

    Write-Host ''

    # ══════════════════════════════════════════════════════════════════════
    # SN-OAUTH-002 — OIDC Provider Configuration
    # ══════════════════════════════════════════════════════════════════════
    Write-DiagStep 'SN-OAUTH-002: Querying OIDC provider configurations...' -Status 'Info'

    $oidcProviders = $null
    $oidcResult = Invoke-SNApi -BaseUrl $baseUrl -Headers $headers -Endpoint 'table/oidc_provider_configuration?sysparm_limit=5'

    if ($oidcResult.Success) {
        $oidcProviders = $oidcResult.Data.result
        $count = @($oidcProviders).Count

        if ($count -gt 0) {
            Write-DiagStep "  Found $count OIDC provider(s)" -Status 'Success'
            foreach ($p in $oidcProviders) {
                Write-DiagStep "    • $($p.name)" -Status 'Info'
            }
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-002'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Passed'
                Result            = "Found $count OIDC provider configuration(s)"
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = ''
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
        }
        else {
            Write-DiagStep '  No OIDC provider configurations found' -Status 'Error'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-002'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Failed'
                Result            = 'No OIDC provider configurations exist in ServiceNow'
                Remediation       = 'Navigate to System OAuth > OIDC Provider Configuration and create an entry for your identity provider (e.g., Entra ID).'
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = 'oidc_provider_configuration table is empty — OIDC identity federation is not set up'
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
        }
    }
    else {
        if ($oidcResult.StatusCode -eq 403) {
            Write-DiagStep '  403 Forbidden — admin role required to read oidc_provider_configuration' -Status 'Warning'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-002'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Warning'
                Result            = 'Admin access required for OAuth diagnostics'
                Remediation       = $adminRemediation
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = 'Current credentials lack admin role; oidc_provider_configuration table returned 403'
                Confidence        = 'Medium'
                GatingSignal      = 'Yes'
            }
        }
        else {
            Write-DiagStep "  Failed: $($oidcResult.Error)" -Status 'Error'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-002'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Failed'
                Result            = "Error querying oidc_provider_configuration: $($oidcResult.Error)"
                Remediation       = 'Verify ServiceNow connectivity and credentials, then retry.'
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = "REST call to oidc_provider_configuration failed: $($oidcResult.Error)"
                Confidence        = 'Medium'
                GatingSignal      = 'Yes'
            }
        }
    }

    Write-Host ''

    # ══════════════════════════════════════════════════════════════════════
    # SN-OAUTH-003 — Redirect URL Validation
    # ══════════════════════════════════════════════════════════════════════
    Write-DiagStep 'SN-OAUTH-003: Validating redirect URL for Power Platform...' -Status 'Info'

    $expectedCallback = 'https://global.consent.azure-apim.net/redirect'

    if ($oauthEntities -and @($oauthEntities).Count -gt 0) {
        $foundValidRedirect = $false
        foreach ($entity in $oauthEntities) {
            $redirectUrl = $entity.redirect_url
            if ($redirectUrl -and $redirectUrl -like "*$expectedCallback*") {
                Write-DiagStep "  Redirect URL contains expected callback: $redirectUrl" -Status 'Success'
                $foundValidRedirect = $true
                break
            }
        }

        if ($foundValidRedirect) {
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-003'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Passed'
                Result            = "Redirect URL contains expected Power Platform callback ($expectedCallback)"
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = ''
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
        }
        else {
            $actualUrls = ($oauthEntities | ForEach-Object { $_.redirect_url }) -join '; '
            Write-DiagStep "  Expected callback not found. Current redirect URLs: $actualUrls" -Status 'Error'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-003'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "Redirect URL does not contain '$expectedCallback'. Found: $actualUrls"
                Remediation       = "Update the OAuth Application Registry entry in ServiceNow: set Redirect URL to '$expectedCallback'. Navigate to System OAuth > Application Registry and edit the relevant entry."
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = "Power Platform callback URL is missing from the OAuth entity redirect_url field"
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
        }
    }
    else {
        Write-DiagStep '  Skipped — no OAuth entity data available from SN-OAUTH-001' -Status 'Warning'
        $results += [PSCustomObject]@{
            CheckpointId      = 'SN-OAUTH-003'
            Category          = 'ServiceNow'
            Priority          = 'High'
            Status            = 'Warning'
            Result            = 'Could not validate redirect URL — OAuth entity data unavailable (see SN-OAUTH-001)'
            Remediation       = 'Resolve SN-OAUTH-001 first, then re-run diagnostics.'
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = 'Upstream dependency SN-OAUTH-001 did not return entity data'
            Confidence        = 'Low'
            GatingSignal      = 'Advisory'
        }
    }

    Write-Host ''

    # ══════════════════════════════════════════════════════════════════════
    # SN-OAUTH-004 — Token Lifespan Check
    # ══════════════════════════════════════════════════════════════════════
    Write-DiagStep 'SN-OAUTH-004: Checking token lifespans...' -Status 'Info'

    $minAccessLifespan  = 600       # 10 minutes
    $minRefreshLifespan = 8640000   # 100 days

    if ($oauthEntities -and @($oauthEntities).Count -gt 0) {
        $lifespanIssues = @()

        foreach ($entity in $oauthEntities) {
            $accessLifespan  = [int]$entity.access_token_lifespan
            $refreshLifespan = [int]$entity.refresh_token_lifespan

            if ($accessLifespan -gt 0 -and $accessLifespan -lt $minAccessLifespan) {
                $lifespanIssues += "OAuth entity '$($entity.name)': access_token_lifespan=$accessLifespan (minimum $minAccessLifespan)"
            }
            if ($refreshLifespan -gt 0 -and $refreshLifespan -lt $minRefreshLifespan) {
                $lifespanIssues += "OAuth entity '$($entity.name)': refresh_token_lifespan=$refreshLifespan (minimum $minRefreshLifespan)"
            }
        }

        if ($lifespanIssues.Count -eq 0) {
            Write-DiagStep '  Token lifespans meet minimum thresholds' -Status 'Success'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-004'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Passed'
                Result            = "Token lifespans are within acceptable ranges (access >= ${minAccessLifespan}s, refresh >= ${minRefreshLifespan}s)"
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = ''
                Confidence        = 'High'
                GatingSignal      = 'Advisory'
            }
        }
        else {
            $issueDetail = $lifespanIssues -join ' | '
            Write-DiagStep "  Token lifespan issue(s): $issueDetail" -Status 'Error'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-004'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "Token lifespan below minimum: $issueDetail"
                Remediation       = "In ServiceNow > System OAuth > Application Registry, update the relevant entry: set Access Token Lifespan >= $minAccessLifespan seconds and Refresh Token Lifespan >= $minRefreshLifespan seconds."
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = 'Short token lifespans cause frequent authentication failures and session drops'
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
        }
    }
    else {
        Write-DiagStep '  Skipped — no OAuth entity data available from SN-OAUTH-001' -Status 'Warning'
        $results += [PSCustomObject]@{
            CheckpointId      = 'SN-OAUTH-004'
            Category          = 'ServiceNow'
            Priority          = 'High'
            Status            = 'Warning'
            Result            = 'Could not validate token lifespans — OAuth entity data unavailable (see SN-OAUTH-001)'
            Remediation       = 'Resolve SN-OAUTH-001 first, then re-run diagnostics.'
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = 'Upstream dependency SN-OAUTH-001 did not return entity data'
            Confidence        = 'Low'
            GatingSignal      = 'Advisory'
        }
    }

    Write-Host ''

    # ══════════════════════════════════════════════════════════════════════
    # SN-OAUTH-005 — User Claim Mapping
    # ══════════════════════════════════════════════════════════════════════
    Write-DiagStep 'SN-OAUTH-005: Checking OIDC user claim mapping...' -Status 'Info'

    if ($oidcProviders -and @($oidcProviders).Count -gt 0) {
        $claimIssues = @()

        foreach ($p in $oidcProviders) {
            $userClaim = $p.user_claim
            if ($userClaim -and ($userClaim -eq 'email' -or $userClaim -eq 'sub')) {
                Write-DiagStep "  Provider '$($p.name)' user_claim='$userClaim'" -Status 'Success'
            }
            elseif ($userClaim) {
                $claimIssues += "Provider '$($p.name)' has user_claim='$userClaim' (expected 'email' or 'sub')"
            }
            else {
                $claimIssues += "Provider '$($p.name)' has no user_claim configured"
            }
        }

        if ($claimIssues.Count -eq 0) {
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-005'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Passed'
                Result            = 'All OIDC providers have a valid user claim mapping (email or sub)'
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = ''
                Confidence        = 'High'
                GatingSignal      = 'Advisory'
            }
        }
        else {
            $issueDetail = $claimIssues -join ' | '
            Write-DiagStep "  Claim mapping issue(s): $issueDetail" -Status 'Error'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-005'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "User claim mapping issue: $issueDetail"
                Remediation       = "In ServiceNow > System OAuth > OIDC Provider Configuration, set the User Claim field to 'email' (preferred) or 'sub'. This tells ServiceNow which JWT claim to use for user identity matching."
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = 'Incorrect or missing user_claim prevents ServiceNow from mapping the OIDC token to a local user account'
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
        }
    }
    else {
        Write-DiagStep '  Skipped — no OIDC provider data available from SN-OAUTH-002' -Status 'Warning'
        $results += [PSCustomObject]@{
            CheckpointId      = 'SN-OAUTH-005'
            Category          = 'ServiceNow'
            Priority          = 'High'
            Status            = 'Warning'
            Result            = 'Could not validate user claim mapping — OIDC provider data unavailable (see SN-OAUTH-002)'
            Remediation       = 'Resolve SN-OAUTH-002 first, then re-run diagnostics.'
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = 'Upstream dependency SN-OAUTH-002 did not return provider data'
            Confidence        = 'Low'
            GatingSignal      = 'Advisory'
        }
    }

    Write-Host ''

    # ══════════════════════════════════════════════════════════════════════
    # SN-OAUTH-006 — OAuth Application Scope for ESS
    # ══════════════════════════════════════════════════════════════════════
    Write-DiagStep 'SN-OAUTH-006: Checking OAuth application scope for ESS integration...' -Status 'Info'

    if ($oauthEntities -and @($oauthEntities).Count -gt 0) {
        $scopeFound = $false

        foreach ($entity in $oauthEntities) {
            $appScope = $entity.application_scope
            if ($appScope) {
                Write-DiagStep "  OAuth entity '$($entity.name)' has application scope: $appScope" -Status 'Success'
                $scopeFound = $true
            }
        }

        if ($scopeFound) {
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-006'
                Category          = 'ServiceNow'
                Priority          = 'Medium'
                Status            = 'Passed'
                Result            = 'At least one OAuth entity has an application scope configured'
                Remediation       = ''
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = ''
                Confidence        = 'Medium'
                GatingSignal      = 'Advisory'
            }
        }
        else {
            Write-DiagStep '  No OAuth entities have an application scope configured' -Status 'Warning'
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-OAUTH-006'
                Category          = 'ServiceNow'
                Priority          = 'Medium'
                Status            = 'Warning'
                Result            = 'No OAuth entity has an explicit application scope — ESS integration may use global scope'
                Remediation       = 'Consider creating a dedicated application scope for the ESS integration in ServiceNow to limit API access. Navigate to System OAuth > Application Registry and configure the scope field.'
                DocumentationLink = $docLink
                Stage             = 'Diagnosis'
                RootCause         = 'OAuth entities are configured without an explicit application scope, which may cause over-permissioned API access'
                Confidence        = 'Medium'
                GatingSignal      = 'Advisory'
            }
        }
    }
    else {
        Write-DiagStep '  Skipped — no OAuth entity data available from SN-OAUTH-001' -Status 'Warning'
        $results += [PSCustomObject]@{
            CheckpointId      = 'SN-OAUTH-006'
            Category          = 'ServiceNow'
            Priority          = 'Medium'
            Status            = 'Warning'
            Result            = 'Could not validate application scope — OAuth entity data unavailable (see SN-OAUTH-001)'
            Remediation       = 'Resolve SN-OAUTH-001 first, then re-run diagnostics.'
            DocumentationLink = $docLink
            Stage             = 'Diagnosis'
            RootCause         = 'Upstream dependency SN-OAUTH-001 did not return entity data'
            Confidence        = 'Low'
            GatingSignal      = 'Advisory'
        }
    }

    # ── Summary ──────────────────────────────────────────────────────────
    Write-Host ''
    Write-Host ('═' * 75) -ForegroundColor Cyan
    Write-Host 'ServiceNow OAuth/OIDC Diagnostics Complete' -ForegroundColor Green
    Write-Host ('═' * 75) -ForegroundColor Cyan

    $passed   = @($results | Where-Object { $_.Status -eq 'Passed'  }).Count
    $failed   = @($results | Where-Object { $_.Status -eq 'Failed'  }).Count
    $warnings = @($results | Where-Object { $_.Status -eq 'Warning' }).Count

    Write-Host "`nDiagnostic Summary:" -ForegroundColor Yellow
    Write-Host "  Total Checks: $($results.Count)" -ForegroundColor White
    Write-Host "  ✓ Passed:     $passed" -ForegroundColor Green
    Write-Host "  ✗ Failed:     $failed" -ForegroundColor Red
    Write-Host "  ⚠ Warnings:   $warnings" -ForegroundColor Yellow

    Write-Host "`nDetailed Results:" -ForegroundColor Yellow
    foreach ($r in $results) {
        $statusIcon = switch ($r.Status) {
            'Passed'  { '✓' }
            'Failed'  { '✗' }
            'Warning' { '⚠' }
            default   { '→' }
        }
        $statusColor = switch ($r.Status) {
            'Passed'  { 'Green'  }
            'Failed'  { 'Red'    }
            'Warning' { 'Yellow' }
            default   { 'White'  }
        }
        Write-Host "  $statusIcon [$($r.CheckpointId)] " -ForegroundColor $statusColor -NoNewline
        Write-Host "$($r.Result)" -ForegroundColor Gray
        if ($r.Remediation) {
            Write-Host "    Remediation: $($r.Remediation)" -ForegroundColor DarkYellow
        }
    }

    Write-Host ''

    return $results
}

try { Export-ModuleMember -Function Test-ServiceNowOAuthConfig } catch { }
