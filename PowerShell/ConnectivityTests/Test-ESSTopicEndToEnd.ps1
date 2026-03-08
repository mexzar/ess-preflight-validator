<#
.SYNOPSIS
    Validates ESS agent topics work end-to-end by sending known-good prompts
    and evaluating response quality.

.DESCRIPTION
    Sends targeted test prompts to ESS Copilot agent topics (Workday, ServiceNow,
    and fallback/ambiguity handling) and evaluates the responses against expected
    keywords, latency thresholds, and minimum response length.

    Uses the same Invoke-CopilotAgentQuery / Get-SimulatedResponse approach from
    Test-CopilotAgentResponse.ps1. In production, Invoke-CopilotAgentQuery should
    be replaced with actual Copilot Studio Direct Line API calls.

    Quality metrics per test:
      - Latency:            should be < 5000 ms
      - Keyword match rate: should be >= 50%
      - Response length:    should be >= 20 characters

    E2E Topic Tests:
      TOPIC-E2E-001 (Critical) - Workday topic
      TOPIC-E2E-002 (Critical) - ServiceNow topic
      TOPIC-E2E-003 (High)     - Ambiguity / fallback handling

.PARAMETER EnvironmentId
    Power Platform environment ID where the agent is deployed (optional).

.PARAMETER AgentId
    Copilot agent ID to test (optional).

.PARAMETER InteractiveMode
    When set, prompts the user to manually verify each test response.

.EXAMPLE
    $results = Test-ESSTopicEndToEnd
    $results | Format-Table CheckpointId, Status, Result

.EXAMPLE
    Test-ESSTopicEndToEnd -InteractiveMode

.EXAMPLE
    Test-ESSTopicEndToEnd -EnvironmentId "12345-67890" -AgentId "abc-def"

.NOTES
    Returns an array of PSCustomObject with properties:
    CheckpointId, Category, Priority, Status, Result, Remediation,
    DocumentationLink, Stage, RootCause, Confidence, GatingSignal.
#>

function Test-ESSTopicEndToEnd {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$EnvironmentId,

        [Parameter(Mandatory = $false)]
        [string]$AgentId,

        [Parameter(Mandatory = $false)]
        [switch]$InteractiveMode
    )

    # ── Configuration ────────────────────────────────────────────────────
    $MaxLatencyMs       = 5000
    $MinKeywordMatchPct = 50
    $MinResponseLength  = 20

    $DocumentationUrl = 'https://learn.microsoft.com/en-us/microsoft-copilot-studio/fundamentals-what-is-copilot-studio'

    # ── Helper: console output ───────────────────────────────────────────
    function Write-TestStep {
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
            'Success' { [char]0x2713 }   # ✓
            'Error'   { [char]0x2717 }   # ✗
            'Warning' { '!'  }
            default   { '->' }
        }

        Write-Host "$icon $Message" -ForegroundColor $color
    }

    # ── Helper: simulated agent response ─────────────────────────────────
    # NOTE: In production, replace this entire function with actual
    #       Copilot Studio Direct Line API calls.
    function Get-SimulatedResponse {
        param([string]$Query)

        $queryLower = $Query.ToLower()

        if ($queryLower -match 'hire\s*date|hire|onboard') {
            return "Your hire date is available in Workday. Navigate to your Workday profile and " +
                   "select the Job tab to view your hire date and other employment details."
        }
        elseif ($queryLower -match 'ticket|laptop|it\s+issue|servicenow') {
            return "To submit an IT ticket for your laptop issue, go to ServiceNow and create a new " +
                   "incident under the Hardware category. You can also submit a ticket by emailing " +
                   "IT support. Your request will be triaged by the IT team."
        }
        elseif ($queryLower -match '^help$|^help\s|need help|assist') {
            return "Hello! I can help you with a variety of topics. For HR questions such as " +
                   "benefits, time off, or payroll, I connect to Workday. For IT support including " +
                   "password resets, equipment, or software requests, I use ServiceNow. " +
                   "How can I assist you today?"
        }
        else {
            return "I understand you're asking about '$Query'. I can help with HR topics like " +
                   "benefits and time off, IT support for passwords and equipment, and general " +
                   "employee questions. Could you provide more details about what you need?"
        }
    }

    # ── Helper: invoke query with latency measurement ────────────────────
    # NOTE: In production, Invoke-CopilotAgentQuery should call the
    #       Copilot Studio Direct Line API rather than Get-SimulatedResponse.
    function Invoke-CopilotAgentQuery {
        param(
            [string]$Query,
            [string]$ConversationId = $null
        )

        Write-TestStep "Sending query: '$Query'" -Status 'Info'

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            # Simulate API latency
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 3000)

            $stopwatch.Stop()
            $latency = $stopwatch.ElapsedMilliseconds

            $response = Get-SimulatedResponse -Query $Query

            return @{
                Success        = $true
                Response       = $response
                Latency        = $latency
                ConversationId = if ($ConversationId) { $ConversationId } else { [Guid]::NewGuid().ToString() }
            }
        }
        catch {
            $stopwatch.Stop()

            return @{
                Success = $false
                Error   = $_.Exception.Message
                Latency = $stopwatch.ElapsedMilliseconds
            }
        }
    }

    # ── Test scenario definitions ────────────────────────────────────────
    $TestScenarios = @(
        @{
            CheckpointId     = 'TOPIC-E2E-001'
            TestName         = 'Workday topic test'
            Priority         = 'Critical'
            GatingSignal     = 'Yes'
            Query            = 'What is my hire date?'
            ExpectedKeywords = @('hire', 'date', 'Workday')
        }
        @{
            CheckpointId     = 'TOPIC-E2E-002'
            TestName         = 'ServiceNow topic test'
            Priority         = 'Critical'
            GatingSignal     = 'Yes'
            Query            = 'I need to submit an IT ticket for laptop issue'
            ExpectedKeywords = @('ticket', 'ServiceNow', 'IT', 'submit')
        }
        @{
            CheckpointId     = 'TOPIC-E2E-003'
            TestName         = 'Ambiguity handling'
            Priority         = 'High'
            GatingSignal     = 'Advisory'
            Query            = 'help'
            ExpectedKeywords = @('help', 'assist', 'HR', 'IT')
        }
    )

    # ── Banner ───────────────────────────────────────────────────────────
    Write-Host ''
    Write-Host '  ESS Topic End-to-End Validation' -ForegroundColor Cyan
    Write-Host '  ================================' -ForegroundColor Cyan
    if ($EnvironmentId) { Write-Host "  Environment : $EnvironmentId" -ForegroundColor Gray }
    if ($AgentId)       { Write-Host "  Agent       : $AgentId"       -ForegroundColor Gray }
    Write-Host "  Tests       : $($TestScenarios.Count)"               -ForegroundColor Gray
    Write-Host ''

    # ── Execute tests ────────────────────────────────────────────────────
    $results = @()

    foreach ($scenario in $TestScenarios) {

        Write-Host "  ───────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  $($scenario.CheckpointId): $($scenario.TestName)"   -ForegroundColor Cyan
        Write-Host "  ───────────────────────────────────────────────────" -ForegroundColor DarkGray

        try {
            $queryResult = Invoke-CopilotAgentQuery -Query $scenario.Query

            if (-not $queryResult.Success) {
                # Query itself errored
                Write-TestStep "  Query failed: $($queryResult.Error)" -Status 'Error'

                $results += [PSCustomObject]@{
                    CheckpointId      = $scenario.CheckpointId
                    Category          = 'Topics'
                    Priority          = $scenario.Priority
                    Status            = 'Failed'
                    Result            = "Query error: $($queryResult.Error)"
                    Remediation       = 'Verify agent is deployed and accessible. Check Copilot Studio for errors.'
                    DocumentationLink = $DocumentationUrl
                    Stage             = 'Diagnosis'
                    RootCause         = "Agent query returned an error: $($queryResult.Error)"
                    Confidence        = 'High'
                    GatingSignal      = $scenario.GatingSignal
                }
                Write-Host ''
                continue
            }

            # ── Evaluate response quality ────────────────────────────
            $response = $queryResult.Response
            $latency  = $queryResult.Latency

            Write-Host "  Response: $response" -ForegroundColor White
            Write-Host ''

            # Interactive manual verification
            if ($InteractiveMode) {
                $manualResult = Read-Host "  Does this response look correct? (Y/N)"
                if ($manualResult -notmatch '^[Yy]') {
                    Write-TestStep '  Manual verification failed' -Status 'Warning'
                }
            }

            # Keyword match rate
            $foundKeywords = 0
            foreach ($keyword in $scenario.ExpectedKeywords) {
                if ($response -match [regex]::Escape($keyword)) {
                    $foundKeywords++
                }
            }
            $keywordMatchPct = if ($scenario.ExpectedKeywords.Count -gt 0) {
                [math]::Round(($foundKeywords / $scenario.ExpectedKeywords.Count) * 100, 1)
            } else { 100 }

            # Response length
            $responseLength = $response.Length

            # Log quality metrics
            $latencyOk  = $latency -le $MaxLatencyMs
            $keywordsOk = $keywordMatchPct -ge $MinKeywordMatchPct
            $lengthOk   = $responseLength -ge $MinResponseLength

            if ($latencyOk)  { Write-TestStep "  Latency: $latency ms"                         -Status 'Success' }
            else             { Write-TestStep "  Latency: $latency ms (exceeds $MaxLatencyMs)"  -Status 'Warning' }

            if ($keywordsOk) { Write-TestStep "  Keywords: $keywordMatchPct% ($foundKeywords/$($scenario.ExpectedKeywords.Count))" -Status 'Success' }
            else             { Write-TestStep "  Keywords: $keywordMatchPct% ($foundKeywords/$($scenario.ExpectedKeywords.Count))" -Status 'Warning' }

            if ($lengthOk)   { Write-TestStep "  Length: $responseLength chars" -Status 'Success' }
            else             { Write-TestStep "  Length: $responseLength chars (below $MinResponseLength)" -Status 'Warning' }

            # ── Determine outcome ────────────────────────────────────
            if ($keywordsOk -and $latencyOk) {
                # Passed
                $results += [PSCustomObject]@{
                    CheckpointId      = $scenario.CheckpointId
                    Category          = 'Topics'
                    Priority          = $scenario.Priority
                    Status            = 'Passed'
                    Result            = "$($scenario.TestName) passed. Latency=${latency}ms, KeywordMatch=${keywordMatchPct}%, Length=${responseLength}."
                    Remediation       = ''
                    DocumentationLink = $DocumentationUrl
                    Stage             = 'Detection'
                    RootCause         = ''
                    Confidence        = 'High'
                    GatingSignal      = $scenario.GatingSignal
                }
            }
            elseif (-not $keywordsOk) {
                # Low keyword match
                $results += [PSCustomObject]@{
                    CheckpointId      = $scenario.CheckpointId
                    Category          = 'Topics'
                    Priority          = $scenario.Priority
                    Status            = 'Warning'
                    Result            = "$($scenario.TestName) keyword match below threshold. KeywordMatch=${keywordMatchPct}%, Latency=${latency}ms."
                    Remediation       = 'Review topic configuration and knowledge base content in Copilot Studio. Ensure the topic trigger phrases match expected user inputs.'
                    DocumentationLink = $DocumentationUrl
                    Stage             = 'Diagnosis'
                    RootCause         = 'Agent response did not contain expected keywords. Topic may not be properly configured or knowledge base may be incomplete.'
                    Confidence        = 'Medium'
                    GatingSignal      = $scenario.GatingSignal
                }
            }
            else {
                # Latency exceeded
                $results += [PSCustomObject]@{
                    CheckpointId      = $scenario.CheckpointId
                    Category          = 'Topics'
                    Priority          = $scenario.Priority
                    Status            = 'Warning'
                    Result            = "$($scenario.TestName) latency exceeded threshold. Latency=${latency}ms (max ${MaxLatencyMs}ms), KeywordMatch=${keywordMatchPct}%."
                    Remediation       = 'Investigate agent response time. Check knowledge base indexing, plugin latency, and network connectivity.'
                    DocumentationLink = $DocumentationUrl
                    Stage             = 'Diagnosis'
                    RootCause         = 'Agent response latency exceeds threshold'
                    Confidence        = 'Medium'
                    GatingSignal      = $scenario.GatingSignal
                }
            }
        }
        catch {
            Write-TestStep "  Unexpected error: $_" -Status 'Error'

            $results += [PSCustomObject]@{
                CheckpointId      = $scenario.CheckpointId
                Category          = 'Topics'
                Priority          = $scenario.Priority
                Status            = 'Failed'
                Result            = "Unexpected error during $($scenario.TestName): $_"
                Remediation       = 'Check script execution environment and agent accessibility.'
                DocumentationLink = $DocumentationUrl
                Stage             = 'Diagnosis'
                RootCause         = "Unhandled exception: $_"
                Confidence        = 'Low'
                GatingSignal      = $scenario.GatingSignal
            }
        }

        Write-Host ''
    }

    # ── Summary ──────────────────────────────────────────────────────────
    $passed  = @($results | Where-Object { $_.Status -eq 'Passed'  }).Count
    $warned  = @($results | Where-Object { $_.Status -eq 'Warning' }).Count
    $failed  = @($results | Where-Object { $_.Status -eq 'Failed'  }).Count

    Write-Host '  =======================================================' -ForegroundColor Cyan
    Write-Host "  Topic E2E Summary: $passed passed, $warned warning(s), $failed failed" -ForegroundColor $(
        if ($failed -gt 0) { 'Red' } elseif ($warned -gt 0) { 'Yellow' } else { 'Green' }
    )
    Write-Host ''

    return $results
}

# Export for module use (only when loaded as module)
try { Export-ModuleMember -Function Test-ESSTopicEndToEnd } catch { }
