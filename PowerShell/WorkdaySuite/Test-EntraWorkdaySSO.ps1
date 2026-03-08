<#
.SYNOPSIS
    Validates the Entra ID (Azure AD) SSO configuration for Workday.

.DESCRIPTION
    Standalone diagnostic script that checks Entra ID enterprise application
    configuration for Workday SSO integration. Uses an ADAPTIVE pattern:
    if the Microsoft Graph session includes Application.Read.All scope,
    automated validation is performed against the Graph API; otherwise,
    a manual checklist with remediation steps is returned.

    Checkpoints validated:
      WD-ENTRA-001  Enterprise App registration exists
      WD-ENTRA-002  SAML SSO mode is configured
      WD-ENTRA-003  App ID URI (identifier) is set
      WD-ENTRA-004  Users/groups are assigned to the app

.PARAMETER EnvironmentId
    Optional Power Platform environment ID for contextual logging.

.PARAMETER WorkdayAppId
    The Workday Enterprise Application (client) ID registered in Entra.
    Defaults to the well-known Workday app ID '4e4707ca-5f53-46a6-a819-f7765446e6ff'.

.EXAMPLE
    Test-EntraWorkdaySSO

.EXAMPLE
    Test-EntraWorkdaySSO -WorkdayAppId 'custom-app-guid-here'

.EXAMPLE
    $results = Test-EntraWorkdaySSO -EnvironmentId '00000000-0000-0000-0000-000000000000'
    $results | Format-Table CheckpointId, Status, Result -AutoSize

.NOTES
    Version: 1.0.0
    Author:  ESS Pre-flight Validator
    Requires: Microsoft.Graph PowerShell SDK (Microsoft.Graph.Applications, Microsoft.Graph.Identity.SignIns)
    Reference: https://learn.microsoft.com/en-us/entra/identity/saas-apps/workday-tutorial
#>

function Test-EntraWorkdaySSO {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$EnvironmentId,

        [Parameter()]
        [string]$WorkdayAppId = '4e4707ca-5f53-46a6-a819-f7765446e6ff'
    )

    $results = @()

    Write-Host ""
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "         ENTRA ID WORKDAY SSO VALIDATOR v1.0                          " -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""

    #region Ensure Graph Connection
    $mgContext = Get-MgContext

    if (-not $mgContext) {
        Write-Host "  ℹ️  No active Microsoft Graph session. Connecting..." -ForegroundColor Yellow
        try {
            Connect-MgGraph -Scopes "Organization.Read.All","Directory.Read.All" -NoWelcome -ErrorAction Stop
            $mgContext = Get-MgContext
            Write-Host "  ✅ Connected to Microsoft Graph as $($mgContext.Account)" -ForegroundColor Green
        }
        catch {
            Write-Host "  ❌ Failed to connect to Microsoft Graph: $($_.Exception.Message)" -ForegroundColor Red
            return @([PSCustomObject]@{
                CheckpointId      = 'WD-ENTRA-000'
                Category          = 'Workday'
                Priority          = 'Critical'
                Status            = 'Failed'
                Result            = "Unable to connect to Microsoft Graph: $($_.Exception.Message)"
                Remediation       = 'Install the Microsoft.Graph module (Install-Module Microsoft.Graph) and ensure you can authenticate.'
                DocumentationLink = 'https://learn.microsoft.com/en-us/powershell/microsoftgraph/installation'
                Stage             = 'Detection'
                RootCause         = 'Graph authentication failure'
                Confidence        = 'High'
                GatingSignal      = 'Yes'
            })
        }
    }
    else {
        Write-Host "  ✅ Using existing Graph session: $($mgContext.Account)" -ForegroundColor Green
    }
    Write-Host ""
    #endregion

    #region Determine Scope Availability
    $scopes = (Get-MgContext).Scopes
    $hasAppRead = $scopes -contains 'Application.Read.All'

    if ($hasAppRead) {
        Write-Host "  🔑 Application.Read.All scope detected — running automated validation" -ForegroundColor Green
    }
    else {
        Write-Host "  ⚠️  Application.Read.All scope NOT available — generating manual checklist" -ForegroundColor Yellow
        Write-Host "     Current scopes: $($scopes -join ', ')" -ForegroundColor DarkGray
        Write-Host "     To enable automated checks, reconnect with:" -ForegroundColor DarkGray
        Write-Host '     Connect-MgGraph -Scopes "Application.Read.All","Organization.Read.All","Directory.Read.All"' -ForegroundColor DarkGray
    }
    Write-Host ""
    #endregion

    # ─── Documentation link shared by all checkpoints ───
    $docsLink = 'https://learn.microsoft.com/en-us/entra/identity/saas-apps/workday-tutorial'

    if ($hasAppRead) {
        #region ═══ AUTOMATED MODE ═══

        # ── WD-ENTRA-001: Enterprise App exists ──
        Write-Host "  🔍 WD-ENTRA-001: Checking Enterprise App registration..." -ForegroundColor Cyan
        try {
            $sp = Get-MgServicePrincipal -Filter "appId eq '$WorkdayAppId'" -ErrorAction Stop

            if ($sp) {
                Write-Host "  ✅ Enterprise App found: $($sp.DisplayName) (ObjectId: $($sp.Id))" -ForegroundColor Green
                $results += [PSCustomObject]@{
                    CheckpointId      = 'WD-ENTRA-001'
                    Category          = 'Workday'
                    Priority          = 'Critical'
                    Status            = 'Passed'
                    Result            = "Enterprise App '$($sp.DisplayName)' exists (AppId: $WorkdayAppId)"
                    Remediation       = ''
                    DocumentationLink = $docsLink
                    Stage             = 'Detection'
                    RootCause         = ''
                    Confidence        = 'High'
                    GatingSignal      = 'Yes'
                }
            }
            else {
                Write-Host "  ❌ Enterprise App NOT found for AppId: $WorkdayAppId" -ForegroundColor Red
                $results += [PSCustomObject]@{
                    CheckpointId      = 'WD-ENTRA-001'
                    Category          = 'Workday'
                    Priority          = 'Critical'
                    Status            = 'Failed'
                    Result            = "No Enterprise App found with AppId '$WorkdayAppId'"
                    Remediation       = "Register the Workday Enterprise App in Entra ID > Enterprise Applications > New Application > search 'Workday'."
                    DocumentationLink = $docsLink
                    Stage             = 'Detection'
                    RootCause         = 'Enterprise App not registered in Entra ID'
                    Confidence        = 'High'
                    GatingSignal      = 'Yes'
                }
                # Cannot continue automated checks without the service principal
                Write-Host "  ⚠️  Skipping remaining automated checks (Enterprise App required)" -ForegroundColor Yellow
                return $results
            }
        }
        catch {
            Write-Host "  ❌ Error querying service principal: $($_.Exception.Message)" -ForegroundColor Red
            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-ENTRA-001'
                Category          = 'Workday'
                Priority          = 'Critical'
                Status            = 'Failed'
                Result            = "Error querying Enterprise App: $($_.Exception.Message)"
                Remediation       = 'Ensure you have sufficient permissions and the Microsoft.Graph.Applications module is installed.'
                DocumentationLink = $docsLink
                Stage             = 'Detection'
                RootCause         = 'Graph API query failure'
                Confidence        = 'Medium'
                GatingSignal      = 'Yes'
            }
            return $results
        }
        Write-Host ""

        # ── WD-ENTRA-002: SAML SSO configured ──
        Write-Host "  🔍 WD-ENTRA-002: Checking SAML SSO configuration..." -ForegroundColor Cyan
        $ssoMode = $sp.PreferredSingleSignOnMode

        if ($ssoMode -eq 'saml') {
            Write-Host "  ✅ SSO mode is SAML" -ForegroundColor Green
            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-ENTRA-002'
                Category          = 'Workday'
                Priority          = 'High'
                Status            = 'Passed'
                Result            = "SAML SSO is configured (PreferredSingleSignOnMode = 'saml')"
                Remediation       = ''
                DocumentationLink = $docsLink
                Stage             = 'Detection'
                RootCause         = ''
                Confidence        = 'High'
                GatingSignal      = 'Advisory'
            }
        }
        elseif ($ssoMode) {
            Write-Host "  ⚠️  SSO mode is '$ssoMode' (expected 'saml')" -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-ENTRA-002'
                Category          = 'Workday'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "SSO mode is '$ssoMode' — expected 'saml'"
                Remediation       = "In Entra ID > Enterprise Applications > $($sp.DisplayName) > Single sign-on, select SAML as the SSO method and complete the configuration."
                DocumentationLink = $docsLink
                Stage             = 'Detection'
                RootCause         = "PreferredSingleSignOnMode is '$ssoMode' instead of 'saml'"
                Confidence        = 'High'
                GatingSignal      = 'Advisory'
            }
        }
        else {
            Write-Host "  ❌ SSO mode is NOT configured" -ForegroundColor Red
            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-ENTRA-002'
                Category          = 'Workday'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "PreferredSingleSignOnMode is not set — SAML SSO has not been configured"
                Remediation       = "In Entra ID > Enterprise Applications > $($sp.DisplayName) > Single sign-on, select SAML and configure the sign-on URL, identifier, and reply URL per Workday documentation."
                DocumentationLink = $docsLink
                Stage             = 'Detection'
                RootCause         = 'SAML SSO not configured on the Enterprise App'
                Confidence        = 'High'
                GatingSignal      = 'Advisory'
            }
        }
        Write-Host ""

        # ── WD-ENTRA-003: App ID URI (Identifier) configured ──
        Write-Host "  🔍 WD-ENTRA-003: Checking Application ID URI..." -ForegroundColor Cyan
        try {
            $app = Get-MgApplication -Filter "appId eq '$WorkdayAppId'" -ErrorAction Stop
            $identifierUris = $app.IdentifierUris

            if ($identifierUris -and $identifierUris.Count -gt 0) {
                Write-Host "  ✅ Identifier URI(s): $($identifierUris -join ', ')" -ForegroundColor Green
                $results += [PSCustomObject]@{
                    CheckpointId      = 'WD-ENTRA-003'
                    Category          = 'Workday'
                    Priority          = 'High'
                    Status            = 'Passed'
                    Result            = "App ID URI configured: $($identifierUris -join ', ')"
                    Remediation       = ''
                    DocumentationLink = $docsLink
                    Stage             = 'Detection'
                    RootCause         = ''
                    Confidence        = 'High'
                    GatingSignal      = 'Advisory'
                }
            }
            else {
                Write-Host "  ❌ No Identifier URI configured" -ForegroundColor Red
                $results += [PSCustomObject]@{
                    CheckpointId      = 'WD-ENTRA-003'
                    Category          = 'Workday'
                    Priority          = 'High'
                    Status            = 'Failed'
                    Result            = 'No Identifier URI (App ID URI) is configured on the application'
                    Remediation       = "In Entra ID > App registrations > $($app.DisplayName) > Expose an API, set the Application ID URI to match your Workday tenant URL (e.g., https://wd3-impl-services1.workday.com/ccx/service/<tenant>)."
                    DocumentationLink = $docsLink
                    Stage             = 'Detection'
                    RootCause         = 'Application IdentifierUris collection is empty'
                    Confidence        = 'High'
                    GatingSignal      = 'Advisory'
                }
            }
        }
        catch {
            Write-Host "  ⚠️  Could not query application registration: $($_.Exception.Message)" -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-ENTRA-003'
                Category          = 'Workday'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "Error querying application registration: $($_.Exception.Message)"
                Remediation       = 'Ensure Application.Read.All permission is consented and the application registration exists.'
                DocumentationLink = $docsLink
                Stage             = 'Detection'
                RootCause         = 'Graph API query failure for application object'
                Confidence        = 'Medium'
                GatingSignal      = 'Advisory'
            }
        }
        Write-Host ""

        # ── WD-ENTRA-004: Users/groups assigned ──
        Write-Host "  🔍 WD-ENTRA-004: Checking user/group assignments..." -ForegroundColor Cyan
        try {
            $assignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction Stop

            if ($assignments -and $assignments.Count -gt 0) {
                $userCount  = ($assignments | Where-Object { $_.PrincipalType -eq 'User' }).Count
                $groupCount = ($assignments | Where-Object { $_.PrincipalType -eq 'Group' }).Count
                Write-Host "  ✅ $($assignments.Count) assignment(s) found ($userCount user(s), $groupCount group(s))" -ForegroundColor Green

                $results += [PSCustomObject]@{
                    CheckpointId      = 'WD-ENTRA-004'
                    Category          = 'Workday'
                    Priority          = 'High'
                    Status            = 'Passed'
                    Result            = "$($assignments.Count) app role assignment(s): $userCount user(s), $groupCount group(s)"
                    Remediation       = ''
                    DocumentationLink = $docsLink
                    Stage             = 'Detection'
                    RootCause         = ''
                    Confidence        = 'High'
                    GatingSignal      = 'Advisory'
                }
            }
            else {
                Write-Host "  ❌ No users or groups assigned to the Enterprise App" -ForegroundColor Red
                $results += [PSCustomObject]@{
                    CheckpointId      = 'WD-ENTRA-004'
                    Category          = 'Workday'
                    Priority          = 'High'
                    Status            = 'Failed'
                    Result            = 'No users or groups are assigned to the Workday Enterprise App'
                    Remediation       = "In Entra ID > Enterprise Applications > $($sp.DisplayName) > Users and groups, assign the users or groups that need Workday SSO access."
                    DocumentationLink = $docsLink
                    Stage             = 'Detection'
                    RootCause         = 'No app role assignments found on the service principal'
                    Confidence        = 'High'
                    GatingSignal      = 'Advisory'
                }
            }
        }
        catch {
            Write-Host "  ⚠️  Could not query app role assignments: $($_.Exception.Message)" -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                CheckpointId      = 'WD-ENTRA-004'
                Category          = 'Workday'
                Priority          = 'High'
                Status            = 'Failed'
                Result            = "Error querying app role assignments: $($_.Exception.Message)"
                Remediation       = 'Ensure Directory.Read.All permission is consented.'
                DocumentationLink = $docsLink
                Stage             = 'Detection'
                RootCause         = 'Graph API query failure for app role assignments'
                Confidence        = 'Medium'
                GatingSignal      = 'Advisory'
            }
        }
        Write-Host ""
        #endregion
    }
    else {
        #region ═══ MANUAL CHECKLIST MODE ═══
        Write-Host "  📋 Generating manual verification checklist..." -ForegroundColor Cyan
        Write-Host ""

        # WD-ENTRA-001 — Manual
        Write-Host "  ☐  WD-ENTRA-001: Verify Enterprise App exists" -ForegroundColor Yellow
        Write-Host "     → Entra ID > Enterprise Applications > search 'Workday'" -ForegroundColor DarkGray
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-ENTRA-001'
            Category          = 'Workday'
            Priority          = 'Critical'
            Status            = 'NotConfigured'
            Result            = "MANUAL CHECK REQUIRED: Verify the Workday Enterprise App (AppId: $WorkdayAppId) exists in Entra ID."
            Remediation       = "Open the Azure Portal > Entra ID > Enterprise Applications. Search for 'Workday'. If not found, click '+ New Application', search for 'Workday', and follow the setup wizard. Ensure the Application (client) ID matches '$WorkdayAppId'."
            DocumentationLink = $docsLink
            Stage             = 'Remediation'
            RootCause         = 'Automated validation unavailable — Application.Read.All scope not granted'
            Confidence        = 'Low'
            GatingSignal      = 'Yes'
        }
        Write-Host ""

        # WD-ENTRA-002 — Manual
        Write-Host "  ☐  WD-ENTRA-002: Verify SAML SSO is configured" -ForegroundColor Yellow
        Write-Host "     → Enterprise App > Single sign-on > SAML" -ForegroundColor DarkGray
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-ENTRA-002'
            Category          = 'Workday'
            Priority          = 'High'
            Status            = 'NotConfigured'
            Result            = "MANUAL CHECK REQUIRED: Verify SAML is selected as the SSO method on the Workday Enterprise App."
            Remediation       = "Open the Azure Portal > Entra ID > Enterprise Applications > Workday > Single sign-on. Select 'SAML' as the method. Configure: (1) Identifier (Entity ID) — your Workday tenant URL, (2) Reply URL — the Workday ACS endpoint, (3) Sign on URL — the Workday login URL. Download the Federation Metadata XML or Certificate (Base64) for upload into Workday."
            DocumentationLink = $docsLink
            Stage             = 'Remediation'
            RootCause         = 'Automated validation unavailable — Application.Read.All scope not granted'
            Confidence        = 'Low'
            GatingSignal      = 'Advisory'
        }
        Write-Host ""

        # WD-ENTRA-003 — Manual
        Write-Host "  ☐  WD-ENTRA-003: Verify Application ID URI is set" -ForegroundColor Yellow
        Write-Host "     → App registrations > Workday > Expose an API" -ForegroundColor DarkGray
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-ENTRA-003'
            Category          = 'Workday'
            Priority          = 'High'
            Status            = 'NotConfigured'
            Result            = "MANUAL CHECK REQUIRED: Verify the Application ID URI is configured for the Workday app registration."
            Remediation       = "Open the Azure Portal > Entra ID > App registrations > Workday. Navigate to 'Expose an API'. The Application ID URI should be set to your Workday tenant SAML entity ID (e.g., https://wd3-impl-services1.workday.com/ccx/service/<tenant>). If empty, click 'Set' and provide the correct URI."
            DocumentationLink = $docsLink
            Stage             = 'Remediation'
            RootCause         = 'Automated validation unavailable — Application.Read.All scope not granted'
            Confidence        = 'Low'
            GatingSignal      = 'Advisory'
        }
        Write-Host ""

        # WD-ENTRA-004 — Manual
        Write-Host "  ☐  WD-ENTRA-004: Verify users/groups are assigned" -ForegroundColor Yellow
        Write-Host "     → Enterprise App > Users and groups" -ForegroundColor DarkGray
        $results += [PSCustomObject]@{
            CheckpointId      = 'WD-ENTRA-004'
            Category          = 'Workday'
            Priority          = 'High'
            Status            = 'NotConfigured'
            Result            = "MANUAL CHECK REQUIRED: Verify at least one user or group is assigned to the Workday Enterprise App."
            Remediation       = "Open the Azure Portal > Entra ID > Enterprise Applications > Workday > Users and groups. Ensure the Workday-eligible users or a security group containing them is assigned. If 'Assignment required?' is set to Yes under Properties, unassigned users will be blocked from SSO."
            DocumentationLink = $docsLink
            Stage             = 'Remediation'
            RootCause         = 'Automated validation unavailable — Application.Read.All scope not granted'
            Confidence        = 'Low'
            GatingSignal      = 'Advisory'
        }
        Write-Host ""

        Write-Host "  ─────────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  💡 To enable automated validation, reconnect with elevated scopes:" -ForegroundColor Cyan
        Write-Host '     Disconnect-MgGraph' -ForegroundColor White
        Write-Host '     Connect-MgGraph -Scopes "Application.Read.All","Organization.Read.All","Directory.Read.All"' -ForegroundColor White
        Write-Host "     Then re-run this script." -ForegroundColor Cyan
        Write-Host ""
        #endregion
    }

    # ── Summary ──
    $passedCount = ($results | Where-Object { $_.Status -eq 'Passed' }).Count
    $failedCount = ($results | Where-Object { $_.Status -eq 'Failed' }).Count
    $manualCount = ($results | Where-Object { $_.Status -eq 'NotConfigured' }).Count

    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host "  RESULTS: $passedCount passed, $failedCount failed, $manualCount manual check(s)" -ForegroundColor Cyan
    Write-Host "=======================================================================" -ForegroundColor Cyan
    Write-Host ""

    return $results
}

# Export for module use (safe for both dot-source and module import)
try { Export-ModuleMember -Function Test-EntraWorkdaySSO } catch { }
