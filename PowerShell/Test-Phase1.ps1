# Test script to validate Phase 1 in deployment wizard
Remove-Module ESS-Validator -ErrorAction SilentlyContinue
Import-Module .\ESS-Validator.psm1 -Force

# Simulate what Invoke-PhaseValidation does
$results = Test-ESSPrerequisites

$phaseCheckpoints = @("PRE-001", "PRE-002", "PRE-003", "PRE-004", "PRE-005", "PRE-008")
$filteredResults = $results | Where-Object { $_.CheckpointId -in $phaseCheckpoints }

$passed = ($filteredResults | Where-Object { $_.Status -eq 'Passed' }).Count
$failed = ($filteredResults | Where-Object { $_.Status -eq 'Failed' }).Count
$warnings = ($filteredResults | Where-Object { $_.Status -eq 'Warning' }).Count

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PHASE 1 VALIDATION TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total results returned: $($results.Count)" -ForegroundColor Yellow
Write-Host "Filtered results: $($filteredResults.Count)" -ForegroundColor Yellow
Write-Host "  ✓ Passed:   $passed" -ForegroundColor Green
Write-Host "  ✗ Failed:   $failed" -ForegroundColor Red
Write-Host "  ⚠ Warnings: $warnings" -ForegroundColor Yellow
