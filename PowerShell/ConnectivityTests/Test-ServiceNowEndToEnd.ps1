<#
.SYNOPSIS
    End-to-end functional validation of ServiceNow APIs required by the ESS agent.

.DESCRIPTION
    Runs a series of checkpoint tests against a ServiceNow instance to verify that
    HRSD Knowledge Base, HR Cases, ITSM Incidents, and User Lookup APIs are reachable
    and returning data. Each checkpoint produces a structured result object compatible
    with the ESS Preflight Validator reporting pipeline.

    Authentication supports OAuth Bearer tokens or Basic (username/password).
    When parameters are omitted the script prompts interactively.

.PARAMETER EnvironmentId
    Optional Power Platform environment ID for correlation / reporting.

.PARAMETER Instance
    ServiceNow instance name (the subdomain part of <instance>.service-now.com).

.PARAMETER Username
    ServiceNow integration user name. Used for Basic auth and user-lookup test.

.PARAMETER Password
    Password for Basic auth. Ignored when OAuthToken is supplied.

.PARAMETER OAuthToken
    OAuth 2.0 Bearer token. When provided, Basic auth is skipped.

.EXAMPLE
    # Interactive — prompts for missing values
    Test-ServiceNowEndToEnd

.EXAMPLE
    # Non-interactive with Basic auth
    Test-ServiceNowEndToEnd -Instance "contoso" -Username "ess_integration" -Password "s3cret"

.EXAMPLE
    # Non-interactive with OAuth
    Test-ServiceNowEndToEnd -Instance "contoso" -Username "ess_integration" -OAuthToken "eyJ..."

.OUTPUTS
    System.Object[]  — Array of PSCustomObject checkpoint results.

.NOTES
    File   : Test-ServiceNowEndToEnd.ps1
    Author : ESS Preflight Validator
    Requires: PowerShell 5.1+
#>

# ---------------------------------------------------------------------------
# Helper — formatted console output
# ---------------------------------------------------------------------------
function Write-TestStep {
    param(
        [string]$Message,
        [string]$Status = "Info"
    )

    $color = switch ($Status) {
        "Success" { "Green" }
        "Error"   { "Red" }
        "Warning" { "Yellow" }
        default   { "Cyan" }
    }

    $icon = switch ($Status) {
        "Success" { [char]0x2713 }   # ✓
        "Error"   { [char]0x2717 }   # ✗
        "Warning" { [char]0x26A0 }   # ⚠
        default   { [char]0x2192 }   # →
    }

    Write-Host "$icon $Message" -ForegroundColor $color
}

# ---------------------------------------------------------------------------
# Helper — invoke a ServiceNow REST API endpoint
# ---------------------------------------------------------------------------
function Invoke-SNApi {
    <#
    .SYNOPSIS
        Calls a ServiceNow REST API endpoint and returns a normalised result.
    .DESCRIPTION
        Builds the full URL from the base URL and relative path, attaches the
        appropriate Authorization header, and returns a hashtable with Success,
        Data, StatusCode, and Error keys.
    #>
    param(
        [Parameter(Mandatory)][string]$BaseUrl,
        [Parameter(Mandatory)][string]$RelativePath,
        [Parameter(Mandatory)][hashtable]$Headers
    )

    $uri = "$BaseUrl/$RelativePath"

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Get `
                        -ContentType "application/json" -ErrorAction Stop

        return @{
            Success    = $true
            Data       = $response
            StatusCode = 200
            Error      = $null
        }
    }
    catch {
        $statusCode = 0
        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        return @{
            Success    = $false
            Data       = $null
            StatusCode = $statusCode
            Error      = $_.Exception.Message
        }
    }
}

# ---------------------------------------------------------------------------
# Main function
# ---------------------------------------------------------------------------
function Test-ServiceNowEndToEnd {
    [CmdletBinding()]
    param(
        [Parameter()][string]$EnvironmentId,
        [Parameter()][string]$Instance,
        [Parameter()][string]$Username,
        [Parameter()][string]$Password,
        [Parameter()][string]$OAuthToken
    )

    # ── Interactive prompts for missing values ──────────────────────────
    if (-not $Instance) {
        $Instance = Read-Host "Enter ServiceNow instance name (e.g. contoso)"
    }
    if (-not $Username) {
        $Username = Read-Host "Enter ServiceNow username"
    }
    if (-not $OAuthToken -and -not $Password) {
        $securePass = Read-Host "Enter ServiceNow password" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }

    # ── Build base URL & auth header ────────────────────────────────────
    $baseUrl = "https://$Instance.service-now.com/api/now"

    $headers = @{ "Accept" = "application/json" }

    if ($OAuthToken) {
        $headers["Authorization"] = "Bearer $OAuthToken"
        Write-TestStep "Using OAuth Bearer authentication" "Info"
    }
    else {
        $pair  = "${Username}:${Password}"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($pair)
        $b64   = [Convert]::ToBase64String($bytes)
        $headers["Authorization"] = "Basic $b64"
        Write-TestStep "Using Basic authentication" "Info"
    }

    # ── Checkpoint definitions ──────────────────────────────────────────
    $docLink = "https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/servicenow"

    $checkpoints = @(
        @{
            Id           = "SN-E2E-001"
            Name         = "HRSD Knowledge Base"
            Priority     = "Critical"
            Path         = "table/kb_knowledge?sysparm_limit=1&sysparm_query=kb_category.label=HR"
            GatingSignal = "Yes"
            Remediation  = "Ensure the Knowledge Management plugin is active and the integration user has read access to kb_knowledge with HR category articles."
        },
        @{
            Id           = "SN-E2E-002"
            Name         = "HRSD HR Cases"
            Priority     = "Critical"
            Path         = "table/sn_hr_core_case?sysparm_limit=1"
            GatingSignal = "Yes"
            Remediation  = "Ensure the HR Service Delivery (HRSD) plugin is activated and the integration user has read access to sn_hr_core_case."
        },
        @{
            Id           = "SN-E2E-003"
            Name         = "ITSM Incidents"
            Priority     = "High"
            Path         = "table/incident?sysparm_limit=1"
            GatingSignal = "Advisory"
            Remediation  = "Verify the integration user has read access to the incident table via an appropriate ACL or role (e.g. itil)."
        },
        @{
            Id           = "SN-E2E-004"
            Name         = "User Lookup"
            Priority     = "High"
            Path         = "table/sys_user?sysparm_query=user_name=$Username&sysparm_limit=1"
            GatingSignal = "Advisory"
            Remediation  = "Verify the integration user has read access to sys_user and that the queried user_name exists in the instance."
        }
    )

    # ── Execute checkpoints ─────────────────────────────────────────────
    $results = @()

    Write-Host ""
    Write-Host ("=" * 75) -ForegroundColor Cyan
    Write-Host "  ServiceNow End-to-End Validation  —  $Instance.service-now.com" -ForegroundColor Cyan
    Write-Host ("=" * 75) -ForegroundColor Cyan
    Write-Host ""

    foreach ($cp in $checkpoints) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        Write-TestStep "[$($cp.Id)] $($cp.Name) ..." "Info"

        $apiResult = Invoke-SNApi -BaseUrl $baseUrl -RelativePath $cp.Path -Headers $headers
        $stopwatch.Stop()

        # Default result skeleton
        $status     = "Failed"
        $result     = ""
        $stage      = "Detection"
        $rootCause  = ""
        $confidence = "Low"
        $remediation = $cp.Remediation

        if ($apiResult.Success) {
            # HTTP 200 — check whether records were returned
            $hasResults = $false
            if ($apiResult.Data -and $apiResult.Data.result) {
                if ($apiResult.Data.result -is [System.Array]) {
                    $hasResults = $apiResult.Data.result.Count -gt 0
                }
                else {
                    $hasResults = $true
                }
            }

            if ($hasResults) {
                $status     = "Passed"
                $result     = "HTTP 200 — records returned ($($stopwatch.ElapsedMilliseconds) ms)"
                $stage      = "Detection"
                $rootCause  = ""
                $confidence = "High"
                Write-TestStep "  $result" "Success"
            }
            else {
                $status     = "Warning"
                $result     = "HTTP 200 but no records returned ($($stopwatch.ElapsedMilliseconds) ms)"
                $stage      = "Diagnosis"
                $rootCause  = "API reachable but query returned empty result set — verify data exists"
                $confidence = "Medium"
                Write-TestStep "  $result" "Warning"
            }
        }
        else {
            $code = $apiResult.StatusCode

            switch ($code) {
                { $_ -in @(401, 403) } {
                    $result     = "HTTP $code — authentication/authorization failure"
                    $stage      = "Diagnosis"
                    $rootCause  = "Authentication failed - check credentials/permissions"
                    $confidence = "High"
                }
                404 {
                    $result     = "HTTP 404 — table or endpoint not found"
                    $stage      = "Diagnosis"
                    $rootCause  = "Table not found - HRSD plugin may not be activated"
                    $confidence = "High"
                }
                default {
                    if ($code -eq 0) {
                        $result     = "Connection error — $($apiResult.Error)"
                        $stage      = "Diagnosis"
                        $rootCause  = "Cannot reach ServiceNow instance"
                        $confidence = "High"
                    }
                    else {
                        $result     = "HTTP $code — $($apiResult.Error)"
                        $stage      = "Diagnosis"
                        $rootCause  = $apiResult.Error
                        $confidence = "Medium"
                    }
                }
            }

            Write-TestStep "  $result" "Error"
        }

        $results += [PSCustomObject]@{
            CheckpointId      = $cp.Id
            Category          = "ServiceNow"
            Priority          = $cp.Priority
            Status            = $status
            Result            = $result
            Remediation       = $remediation
            DocumentationLink = $docLink
            Stage             = $stage
            RootCause         = $rootCause
            Confidence        = $confidence
            GatingSignal      = $cp.GatingSignal
        }
    }

    # ── Summary ─────────────────────────────────────────────────────────
    $passed  = ($results | Where-Object { $_.Status -eq "Passed" }).Count
    $failed  = ($results | Where-Object { $_.Status -eq "Failed" }).Count
    $warned  = ($results | Where-Object { $_.Status -eq "Warning" }).Count
    $total   = $results.Count

    Write-Host ""
    Write-Host ("=" * 75) -ForegroundColor Cyan
    Write-Host "  Summary: $passed passed, $failed failed, $warned warning(s) out of $total checkpoints" -ForegroundColor $(if ($failed -gt 0) { "Red" } elseif ($warned -gt 0) { "Yellow" } else { "Green" })
    Write-Host ("=" * 75) -ForegroundColor Cyan

    foreach ($r in $results) {
        $icon = switch ($r.Status) {
            "Passed"  { [char]0x2713 }
            "Failed"  { [char]0x2717 }
            "Warning" { [char]0x26A0 }
        }
        $color = switch ($r.Status) {
            "Passed"  { "Green" }
            "Failed"  { "Red" }
            "Warning" { "Yellow" }
        }
        Write-Host "  $icon [$($r.CheckpointId)] $($r.Result)" -ForegroundColor $color
    }

    Write-Host ""

    return $results
}

# ---------------------------------------------------------------------------
# Module export (safe for dot-sourcing and module import)
# ---------------------------------------------------------------------------
try { Export-ModuleMember -Function Test-ServiceNowEndToEnd } catch { }
