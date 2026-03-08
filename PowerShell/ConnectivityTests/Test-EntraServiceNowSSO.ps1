<#
.SYNOPSIS
    Validates the Entra ID SSO / App Registration configuration for ServiceNow.

.DESCRIPTION
    Standalone script that checks whether the ServiceNow API application in Entra ID
    is properly configured for Employee Self-Service.  Uses an ADAPTIVE permission
    model:

      • If the caller's Microsoft Graph session includes Application.Read.All the
        script performs full automated checks against the App Registration and
        Enterprise App (Service Principal).
      • If Application.Read.All is NOT available the script returns every checkpoint
        as NotConfigured with manual verification steps so an admin can self-check.

    Self-contained authentication — the script verifies Get-MgContext and calls
    Connect-MgGraph with the minimum required scopes when no session exists.

.PARAMETER EnvironmentId
    Optional Power Platform environment ID.  Reserved for future correlation
    with environment-scoped validations; not used by the current checks.

.PARAMETER ServiceNowAppClientId
    Application (client) ID of the ServiceNow API scope app registration in
    Entra ID.  Defaults to 'c26b24aa-7874-4e06-ad55-7d06b1f79b63'.

.EXAMPLE
    . .\Test-EntraServiceNowSSO.ps1
    $results = Test-EntraServiceNowSSO
    $results | Format-Table CheckpointId, Status, Result -AutoSize

.EXAMPLE
    Test-EntraServiceNowSSO -ServiceNowAppClientId 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

.NOTES
    Reference: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/servicenow
    Requires the Microsoft.Graph PowerShell SDK (Microsoft.Graph.Applications module).
#>

function Test-EntraServiceNowSSO {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$EnvironmentId,

        [Parameter(Mandatory = $false)]
        [string]$ServiceNowAppClientId = 'c26b24aa-7874-4e06-ad55-7d06b1f79b63'
    )

    $results = @()
    $docLink = 'https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/servicenow-hrsd-itsm'

    # ── Self-contained authentication ────────────────────────────────────────
    Write-Host "`n  🔐 Verifying Microsoft Graph session..." -ForegroundColor Cyan

    $graphContext = Get-MgContext -ErrorAction SilentlyContinue
    if (-not $graphContext) {
        Write-Host "  ℹ️  No active Graph session — connecting with base scopes..." -ForegroundColor Yellow
        try {
            Connect-MgGraph -Scopes "Organization.Read.All", "Directory.Read.All" -NoWelcome
            $graphContext = Get-MgContext
        }
        catch {
            Write-Host "  ❌ Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
            return @([PSCustomObject]@{
                CheckpointId      = 'SN-ENTRA-000'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Failed'
                Result            = "Microsoft Graph connection failed: $_"
                Remediation       = 'Run Connect-MgGraph manually and retry. Ensure the Microsoft.Graph module is installed.'
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = 'Unable to establish a Microsoft Graph session'
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            })
        }
    }
    else {
        Write-Host "  ✅ Microsoft Graph session active (Account: $($graphContext.Account))" -ForegroundColor Green
    }

    # ── Determine permission level ───────────────────────────────────────────
    $hasAppRead = ($graphContext.Scopes -contains 'Application.Read.All')

    if ($hasAppRead) {
        Write-Host "  ✅ Application.Read.All scope available — running automated checks" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠️  Application.Read.All scope NOT available — returning manual verification steps" -ForegroundColor Yellow
    }

    Write-Host ""

    # ═══════════════════════════════════════════════════════════════════════════
    #  AUTOMATED PATH — Application.Read.All is present
    # ═══════════════════════════════════════════════════════════════════════════
    if ($hasAppRead) {

        # ── SN-ENTRA-001  App Registration exists ────────────────────────────
        Write-Host "  🔍 SN-ENTRA-001: Checking App Registration (appId: $ServiceNowAppClientId)..." -ForegroundColor Cyan
        try {
            $app = Get-MgApplication -Filter "appId eq '$ServiceNowAppClientId'" -ErrorAction Stop |
                   Select-Object -First 1

            if ($app) {
                Write-Host "    ✅ App Registration found: $($app.DisplayName) (ObjectId: $($app.Id))" -ForegroundColor Green
                $results += [PSCustomObject]@{
                    CheckpointId      = 'SN-ENTRA-001'
                    Category          = 'ServiceNow'
                    Priority          = 'Critical'
                    Status            = 'Passed'
                    Result            = "App Registration '$($app.DisplayName)' exists (appId: $ServiceNowAppClientId)"
                    Remediation       = ''
                    DocumentationLink = $docLink
                    Stage             = 'Detection'
                    RootCause         = ''
                    Confidence        = 'High'
                    GatingSignal      = 'Yes'
                }
            }
            else {
                Write-Host "    ❌ App Registration NOT found for appId: $ServiceNowAppClientId" -ForegroundColor Red
                $results += [PSCustomObject]@{
                    CheckpointId      = 'SN-ENTRA-001'
                    Category          = 'ServiceNow'
                    Priority          = 'Critical'
                    Status            = 'Failed'
                    Result            = "No App Registration found with appId '$ServiceNowAppClientId'"
                    Remediation       = "Create the ServiceNow API app registration in Entra ID with appId '$ServiceNowAppClientId'. See documentation for required configuration."
                    DocumentationLink = $docLink
                    Stage             = 'Detection'
                    RootCause         = 'ServiceNow App Registration does not exist in this tenant'
                    Confidence        = 'High'
                    GatingSignal      = 'Yes'
                }
                # Remaining checks depend on the app — return early
                return $results
            }
        }
        catch {
            Write-Host "    ❌ Error querying App Registration: $_" -ForegroundColor Red
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-ENTRA-001'
                Category          = 'ServiceNow'
                Priority          = 'Critical'
                Status            = 'Failed'
                Result            = "Error querying App Registration: $_"
                Remediation       = 'Verify Application.Read.All consent and retry.'
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = "Graph API call to Get-MgApplication failed: $_"
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            }
            return $results
        }

        # ── SN-ENTRA-002  Optional claims — email in ID token ────────────────
        Write-Host "  🔍 SN-ENTRA-002: Checking optional claims (email in ID token)..." -ForegroundColor Cyan
        try {
            $hasEmailClaim = $false
            if ($app.OptionalClaims -and $app.OptionalClaims.IdToken) {
                $hasEmailClaim = ($app.OptionalClaims.IdToken | Where-Object { $_.Name -eq 'email' }) -ne $null
            }

            if ($hasEmailClaim) {
                Write-Host "    ✅ 'email' optional claim configured in ID token" -ForegroundColor Green
                $results += [PSCustomObject]@{
                    CheckpointId      = 'SN-ENTRA-002'
                    Category          = 'ServiceNow'
                    Priority          = 'High'
                    Status            = 'Passed'
                    Result            = "'email' optional claim is configured in the ID token"
                    Remediation       = ''
                    DocumentationLink = $docLink
                    Stage             = 'Detection'
                    RootCause         = ''
                    Confidence        = 'High'
                    GatingSignal      = 'Advisory'
                }
            }
            else {
                Write-Host "    ⚠️  'email' optional claim NOT found in ID token" -ForegroundColor Yellow
                $results += [PSCustomObject]@{
                    CheckpointId      = 'SN-ENTRA-002'
                    Category          = 'ServiceNow'
                    Priority          = 'High'
                    Status            = 'Failed'
                    Result            = "'email' optional claim is NOT configured in the ID token"
                    Remediation       = "In Entra ID > App registrations > '$($app.DisplayName)' > Token configuration > Add optional claim > ID token > select 'email'. This ensures ServiceNow receives the user email for identity matching."
                    DocumentationLink = $docLink
                    Stage             = 'Detection'
                    RootCause         = "OptionalClaims.IdToken does not include an 'email' claim"
                    Confidence        = 'High'
                    GatingSignal      = 'Advisory'
                }
            }
        }
        catch {
            Write-Host "    ❌ Error checking optional claims: $_" -ForegroundColor Red
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-ENTRA-002'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "Error checking optional claims: $_"
                Remediation       = 'Manually verify Token configuration in Entra ID > App registrations.'
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = "Failed to inspect OptionalClaims: $_"
                Confidence        = 'Medium'
                GatingSignal      = 'Advisory'
            }
        }

        # ── SN-ENTRA-003  Exposed API scope (user_impersonation) ─────────────
        Write-Host "  🔍 SN-ENTRA-003: Checking exposed API scopes..." -ForegroundColor Cyan
        try {
            $scopes = $app.Api.Oauth2PermissionScopes
            $hasImpersonation = $false
            if ($scopes) {
                $hasImpersonation = ($scopes | Where-Object { $_.Value -like '*user_impersonation*' }) -ne $null
            }

            if ($hasImpersonation) {
                Write-Host "    ✅ 'user_impersonation' scope exposed" -ForegroundColor Green
                $results += [PSCustomObject]@{
                    CheckpointId      = 'SN-ENTRA-003'
                    Category          = 'ServiceNow'
                    Priority          = 'High'
                    Status            = 'Passed'
                    Result            = "Exposed API includes 'user_impersonation' scope"
                    Remediation       = ''
                    DocumentationLink = $docLink
                    Stage             = 'Detection'
                    RootCause         = ''
                    Confidence        = 'High'
                    GatingSignal      = 'Advisory'
                }
            }
            else {
                $scopeList = if ($scopes) { ($scopes | ForEach-Object { $_.Value }) -join ', ' } else { '(none)' }
                Write-Host "    ⚠️  'user_impersonation' scope NOT found. Current scopes: $scopeList" -ForegroundColor Yellow
                $results += [PSCustomObject]@{
                    CheckpointId      = 'SN-ENTRA-003'
                    Category          = 'ServiceNow'
                    Priority          = 'High'
                    Status            = 'Failed'
                    Result            = "'user_impersonation' scope not found in exposed API. Current scopes: $scopeList"
                    Remediation       = "In Entra ID > App registrations > '$($app.DisplayName)' > Expose an API > Add a scope named 'user_impersonation' with Admin and User consent."
                    DocumentationLink = $docLink
                    Stage             = 'Detection'
                    RootCause         = 'Api.Oauth2PermissionScopes does not contain a user_impersonation scope'
                    Confidence        = 'High'
                    GatingSignal      = 'Advisory'
                }
            }
        }
        catch {
            Write-Host "    ❌ Error checking API scopes: $_" -ForegroundColor Red
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-ENTRA-003'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "Error checking exposed API scopes: $_"
                Remediation       = 'Manually verify Expose an API configuration in Entra ID > App registrations.'
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = "Failed to read Api.Oauth2PermissionScopes: $_"
                Confidence        = 'Medium'
                GatingSignal      = 'Advisory'
            }
        }

        # ── SN-ENTRA-004  Enterprise App / Service Principal assignments ─────
        Write-Host "  🔍 SN-ENTRA-004: Checking Enterprise App role assignments..." -ForegroundColor Cyan
        try {
            $sp = Get-MgServicePrincipal -Filter "appId eq '$ServiceNowAppClientId'" -ErrorAction Stop |
                  Select-Object -First 1

            if (-not $sp) {
                Write-Host "    ⚠️  Service Principal (Enterprise App) not found" -ForegroundColor Yellow
                $results += [PSCustomObject]@{
                    CheckpointId      = 'SN-ENTRA-004'
                    Category          = 'ServiceNow'
                    Priority          = 'High'
                    Status            = 'Failed'
                    Result            = "No Service Principal found for appId '$ServiceNowAppClientId'. Enterprise App has not been provisioned."
                    Remediation       = 'Ensure the ServiceNow app has an Enterprise App (Service Principal) in this tenant. Grant admin consent or have a user consent to create one.'
                    DocumentationLink = $docLink
                    Stage             = 'Detection'
                    RootCause         = 'Service Principal does not exist — Enterprise App not provisioned'
                    Confidence        = 'High'
                    GatingSignal      = 'Advisory'
                }
            }
            else {
                $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -ErrorAction Stop

                if ($assignments -and $assignments.Count -gt 0) {
                    Write-Host "    ✅ Enterprise App '$($sp.DisplayName)' has $($assignments.Count) role assignment(s)" -ForegroundColor Green
                    $results += [PSCustomObject]@{
                        CheckpointId      = 'SN-ENTRA-004'
                        Category          = 'ServiceNow'
                        Priority          = 'High'
                        Status            = 'Passed'
                        Result            = "Enterprise App '$($sp.DisplayName)' has $($assignments.Count) app role assignment(s)"
                        Remediation       = ''
                        DocumentationLink = $docLink
                        Stage             = 'Detection'
                        RootCause         = ''
                        Confidence        = 'High'
                        GatingSignal      = 'Advisory'
                    }
                }
                else {
                    Write-Host "    ⚠️  Enterprise App '$($sp.DisplayName)' has NO role assignments" -ForegroundColor Yellow
                    $results += [PSCustomObject]@{
                        CheckpointId      = 'SN-ENTRA-004'
                        Category          = 'ServiceNow'
                        Priority          = 'High'
                        Status            = 'Warning'
                        Result            = "Enterprise App '$($sp.DisplayName)' exists but has no app role assignments"
                        Remediation       = "In Entra ID > Enterprise applications > '$($sp.DisplayName)' > Users and groups > assign users or groups that should access ServiceNow via SSO."
                        DocumentationLink = $docLink
                        Stage             = 'Detection'
                        RootCause         = 'Service Principal has zero AppRoleAssignments — no users/groups are assigned'
                        Confidence        = 'High'
                        GatingSignal      = 'Advisory'
                    }
                }
            }
        }
        catch {
            Write-Host "    ❌ Error checking Enterprise App: $_" -ForegroundColor Red
            $results += [PSCustomObject]@{
                CheckpointId      = 'SN-ENTRA-004'
                Category          = 'ServiceNow'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "Error querying Service Principal or role assignments: $_"
                Remediation       = 'Verify Application.Read.All consent and retry. Check Enterprise App in Entra ID manually.'
                DocumentationLink = $docLink
                Stage             = 'Detection'
                RootCause         = "Graph API call failed: $_"
                Confidence        = 'Medium'
                GatingSignal      = 'Advisory'
            }
        }
    }
    # ═══════════════════════════════════════════════════════════════════════════
    #  MANUAL PATH — Application.Read.All is NOT available
    # ═══════════════════════════════════════════════════════════════════════════
    else {
        Write-Host "  ℹ️  Returning manual verification steps for all ServiceNow Entra checks" -ForegroundColor DarkGray
        Write-Host ""

        $manualChecks = @(
            @{
                Id          = 'SN-ENTRA-001'
                Priority    = 'Critical'
                Title       = 'App Registration exists'
                Remediation = "Open Entra ID > App registrations > search for appId '$ServiceNowAppClientId'. " +
                              "If not found, create a new App Registration for the ServiceNow API scope. " +
                              "To automate this check, re-run with Application.Read.All consent: " +
                              "Connect-MgGraph -Scopes 'Application.Read.All'"
                GatingSignal = 'Yes'
            },
            @{
                Id          = 'SN-ENTRA-002'
                Priority    = 'High'
                Title       = 'Optional claims — email in ID token'
                Remediation = "Open Entra ID > App registrations > ServiceNow app > Token configuration. " +
                              "Verify that an 'email' optional claim is configured for the ID token. " +
                              "If missing, click Add optional claim > ID > select 'email'."
                GatingSignal = 'Advisory'
            },
            @{
                Id          = 'SN-ENTRA-003'
                Priority    = 'High'
                Title       = 'Exposed API scope (user_impersonation)'
                Remediation = "Open Entra ID > App registrations > ServiceNow app > Expose an API. " +
                              "Verify a 'user_impersonation' scope exists. If missing, add a new scope " +
                              "named 'user_impersonation' with Admin and User consent enabled."
                GatingSignal = 'Advisory'
            },
            @{
                Id          = 'SN-ENTRA-004'
                Priority    = 'High'
                Title       = 'Enterprise App user/group assignments'
                Remediation = "Open Entra ID > Enterprise applications > ServiceNow app > Users and groups. " +
                              "Verify that the appropriate users or groups are assigned. " +
                              "If no assignments exist, add the users/groups that require SSO access to ServiceNow."
                GatingSignal = 'Advisory'
            }
        )

        foreach ($check in $manualChecks) {
            $results += [PSCustomObject]@{
                CheckpointId      = $check.Id
                Category          = 'ServiceNow'
                Priority          = $check.Priority
                Status            = 'NotConfigured'
                Result            = "$($check.Title) — manual verification required (Application.Read.All not available)"
                Remediation       = $check.Remediation
                DocumentationLink = $docLink
                Stage             = 'Remediation'
                RootCause         = 'Automated check unavailable — current Graph session lacks Application.Read.All scope'
                Confidence        = 'Low'
                GatingSignal      = $check.GatingSignal
            }
        }
    }

    Write-Host ""
    return $results
}

# Export for module use (only when loaded as module)
try { Export-ModuleMember -Function Test-EntraServiceNowSSO } catch { }
