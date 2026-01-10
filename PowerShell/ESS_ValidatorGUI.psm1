# ==================================================
# ESS Deployment Validation - Complete Test Suite
# ==================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "ESS PRE-FLIGHT VALIDATION TEST SUITE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Ensure reports directory exists
$reportsDir = "C:\Reports"
New-Item -Path $reportsDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# Test 1: Prerequisites (already done, but let's capture results)
Write-Host "`n[TEST 1/5] Prerequisites Validation" -ForegroundColor Magenta
$prereqResults = Test-ESSPrerequisites
$prereqFailed = ($prereqResults | Where-Object Status -eq 'Failed').Count
Write-Host "  Failed: $prereqFailed" -ForegroundColor $(if($prereqFailed -eq 0){'Green'}else{'Red'})

# Test 2: Get Environment
Write-Host "`n[TEST 2/5] Select Target Environment" -ForegroundColor Magenta
$environments = Get-AdminPowerAppEnvironment
$essEnv = $environments | Out-GridView -Title "Select ESS Environment to Validate" -OutputMode Single

if (-not $essEnv) {
    Write-Host "  ❌ No environment selected. Exiting." -ForegroundColor Red
    return
}

Write-Host "  ✅ Selected: $($essEnv.DisplayName)" -ForegroundColor Green
Write-Host "     Environment ID: $($essEnv.EnvironmentName)" -ForegroundColor Gray

# Test 3: Environment Validation
Write-Host "`n[TEST 3/5] Environment Configuration" -ForegroundColor Magenta
$envResults = Test-ESSEnvironment -EnvironmentId $essEnv.EnvironmentName
$envFailed = ($envResults | Where-Object Status -eq 'Failed').Count
Write-Host "  Failed: $envFailed" -ForegroundColor $(if($envFailed -eq 0){'Green'}else{'Red'})

# Test 4: Authentication
Write-Host "`n[TEST 4/5] Authentication & Identity" -ForegroundColor Magenta
$authResults = Test-ESSAuthentication
$authFailed = ($authResults | Where-Object Status -eq 'Failed').Count
Write-Host "  Failed: $authFailed" -ForegroundColor $(if($authFailed -eq 0){'Green'}else{'Red'})

# Test 5: Full Validation with Report
Write-Host "`n[TEST 5/5] Full Validation & Report Generation" -ForegroundColor Magenta
$reportDate = Get-Date -Format 'yyyy-MM-dd-HHmmss'
$reportPath = "$reportsDir\ess-validation-$reportDate.html"

$allResults = Test-ESSDeploymentReadiness -Scope Full `
    -EnvironmentId $essEnv.EnvironmentName `
    -OutputFormat HTML `
    -ExportPath $reportPath `
    -Verbose

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$totalChecks = $allResults.Count
$passed = ($allResults | Where-Object Status -eq 'Passed').Count
$failed = ($allResults | Where-Object Status -eq 'Failed').Count
$warnings = ($allResults | Where-Object Status -eq 'Warning').Count
$notConfigured = ($allResults | Where-Object Status -eq 'NotConfigured').Count

Write-Host "Environment:      $($essEnv.DisplayName)" -ForegroundColor White
Write-Host "Total Checks:     $totalChecks" -ForegroundColor White
Write-Host "✅ Passed:        $passed" -ForegroundColor Green
Write-Host "❌ Failed:        $failed" -ForegroundColor $(if($failed -eq 0){'Green'}else{'Red'})
Write-Host "⚠️  Warnings:      $warnings" -ForegroundColor Yellow
Write-Host "ℹ️  Not Configured: $notConfigured" -ForegroundColor Cyan

# Critical issues
$criticalIssues = $allResults | Where-Object { $_.Status -eq 'Failed' -and $_.Priority -eq 'Critical' }
if ($criticalIssues.Count -gt 0) {
    Write-Host "`n🚨 CRITICAL ISSUES FOUND:" -ForegroundColor Red
    $criticalIssues | ForEach-Object {
        Write-Host "   [$($_.CheckpointId)] $($_.Result)" -ForegroundColor Red
        Write-Host "   → $($_.Remediation)" -ForegroundColor Yellow
    }
    Write-Host "`n❌ DEPLOYMENT BLOCKED - Fix critical issues before proceeding" -ForegroundColor Red
} else {
    Write-Host "`n✅ No critical blockers found!" -ForegroundColor Green
}

# Open report
Write-Host "`nReport saved to: $reportPath" -ForegroundColor Cyan
Write-Host "Opening report in browser..." -ForegroundColor Gray
Start-Process $reportPath

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan