# ESS Pre-flight Validator - Quick Reference Guide

## 🚀 Quick Start - Choose Your Tool

```
┌────────────────────────────────────────────────────────────────────┐
│  What do you need to do?                                           │
├────────────────────────────────────────────────────────────────────┤
│  📦 NEW deployment?          → Use Phased Deployment Wizard        │
│  🔍 Health check?            → Use Full Validator                  │
│  🔌 Test connectivity?       → Use Connectivity Test Suite         │
└────────────────────────────────────────────────────────────────────┘
```

---

## Tool 1: Phased Deployment Wizard

### When to Use
- First-time ESS deployment
- Following Microsoft's deployment guide
- Need step-by-step validation with blocking gates

### Basic Usage
```powershell
cd C:\ESS-PreFlight-Validator\PowerShell
.\Start-ESSDeployment.ps1
```

### Commands
```powershell
# Start or resume from saved progress
.\Start-ESSDeployment.ps1

# Jump to specific phase (if previous phases complete)
.\Start-ESSDeployment.ps1 -StartFromPhase 3

# Reset all progress and start fresh
.\Start-ESSDeployment.ps1 -ResetProgress
```

### What It Does
1. Phase 1: Validates prerequisites (licenses, permissions)
2. Phase 2: Validates environment setup (Power Platform, DLP)
3. Phase 3: Tests external systems (Workday, ServiceNow, SAP)
4. Phase 4: Validates agent configuration
5. Phase 5: Tests functionality and UAT
6. Phase 6: Production readiness checklist

### Output
- Phase-specific HTML reports in `Desktop\ESS-Reports\Deployment\`
- Progress saved to `~/.ess-validator/deployment-state.json`

---

## Tool 2: Full Validator

### When to Use
- Weekly production health checks
- Compliance audits
- Troubleshooting issues
- Validating existing ESS agents

### Basic Usage
```powershell
cd C:\ESS-PreFlight-Validator\PowerShell
.\Start-ESSValidation.ps1
```

### Commands
```powershell
# Full validation (all 200+ checkpoints)
.\Start-ESSValidation.ps1

# Show only failed checks
.\Start-ESSValidation.ps1 -ShowFailedOnly

# Show only critical checks
.\Start-ESSValidation.ps1 -ShowCriticalOnly

# Filter by category
.\Start-ESSValidation.ps1 -Categories "Prerequisites","Authentication"

# Filter by priority
.\Start-ESSValidation.ps1 -Priority "Critical"

# Combine filters
.\Start-ESSValidation.ps1 -Categories "Environment" -Priority "High" -ShowFailedOnly

# Don't auto-open report
.\Start-ESSValidation.ps1 -NoOpenReport

# Skip saved profiles
.\Start-ESSValidation.ps1 -SkipProfile
```

### What It Does
1. Loads saved profile (or creates new)
2. Detects user context
3. Selects environment
4. Runs comprehensive validation
5. Applies filters (if specified)
6. Generates interactive HTML report
7. Auto-opens report in browser

### Output
- HTML report in `Desktop\ESS-Reports\`
- Profile saved to `~/.ess-validator/profiles.json`

### HTML Report Features
- 🔍 Search box (search all fields)
- 🎛️ Status filters (All, Failed, Warnings, Passed)
- 📥 Export buttons (CSV, JSON)
- 📂 Collapsible category sections
- 📊 Clickable summary cards

---

## Tool 3: Connectivity Test Suite

### When to Use
- Daily connectivity monitoring
- Pre-deployment verification
- Incident investigation
- Integration testing

### Basic Usage
```powershell
cd C:\ESS-PreFlight-Validator\PowerShell\ConnectivityTests
.\Invoke-ConnectivitySuite.ps1
```

### Commands
```powershell
# Interactive menu
.\Invoke-ConnectivitySuite.ps1

# Run all tests
.\Invoke-ConnectivitySuite.ps1 -TestSuite All

# Run specific test suite
.\Invoke-ConnectivitySuite.ps1 -TestSuite Workday
.\Invoke-ConnectivitySuite.ps1 -TestSuite ServiceNow
.\Invoke-ConnectivitySuite.ps1 -TestSuite CopilotAgent

# Use config file (automated)
.\Invoke-ConnectivitySuite.ps1 -ConfigFile .\config\prod-tests.json -TestSuite All

# Custom output path
.\Invoke-ConnectivitySuite.ps1 -OutputPath "C:\Reports"
```

### Available Tests
1. **Workday ISU** - SOAP WS-Security authentication
2. **Workday SSO** - OAuth device code flow
3. **ServiceNow** - REST API connectivity
4. **SAP** - OData/RFC (coming soon)
5. **Copilot Agent** - Response quality testing

### Config File Setup
```powershell
# Copy template
cp .\config\prod-tests.json .\config\my-tests.json

# Edit with your credentials
notepad .\config\my-tests.json

# Run with config
.\Invoke-ConnectivitySuite.ps1 -ConfigFile .\config\my-tests.json -TestSuite All
```

### Output
- HTML report in `Desktop\ESS-Reports\`
- Test results with timing metrics

---

## Individual Test Scripts

### Test Workday ISU
```powershell
cd C:\ESS-PreFlight-Validator\PowerShell
.\Test-WorkdayConnectivity.ps1 -Username "ISU_User@tenant" -Password "P@ssw0rd" -Tenant "yourcompany"
```

### Test Workday SSO
```powershell
.\Test-WorkdaySSOConnectivity.ps1 -Tenant "yourcompany"
# Follow device code flow prompts
```

### Test ServiceNow
```powershell
cd ConnectivityTests
.\Test-ServiceNowConnectivity.ps1 -Instance "yourcompany" -Username "admin" -Password "P@ssw0rd"
```

### Test Copilot Agent
```powershell
.\Test-CopilotAgentResponse.ps1 -EnvironmentId "guid" -AgentId "cr123_agent" -TestScenario "Comprehensive"
```

---

## Common Scenarios

### Scenario 1: New Deployment
```powershell
# Use phased wizard
.\Start-ESSDeployment.ps1

# Follow prompts for each phase
# Fix blocking issues as they appear
# Generate phase reports for documentation
```

### Scenario 2: Weekly Health Check
```powershell
# Run full validation
.\Start-ESSValidation.ps1

# Review HTML report
# Export to CSV for trending
# Share report with team
```

### Scenario 3: Daily Connectivity Test
```powershell
# Create config file (one time)
cp ConnectivityTests\config\prod-tests.json ConnectivityTests\config\my-prod.json
notepad ConnectivityTests\config\my-prod.json  # Edit credentials

# Run daily (can be scheduled)
cd ConnectivityTests
.\Invoke-ConnectivitySuite.ps1 -ConfigFile .\config\my-prod.json -TestSuite All
```

### Scenario 4: Troubleshooting
```powershell
# Show only failed checks
.\Start-ESSValidation.ps1 -ShowFailedOnly

# Test specific system
cd ConnectivityTests
.\Test-ServiceNowConnectivity.ps1 -Instance "yourcompany" -Username "user" -Password "pass"

# Review reports for root cause
```

---

## Parameters Reference

### Start-ESSValidation.ps1
| Parameter | Type | Description |
|-----------|------|-------------|
| `-SkipProfile` | Switch | Skip loading saved profiles |
| `-NoOpenReport` | Switch | Don't auto-open HTML report |
| `-ShowFailedOnly` | Switch | Show only failed checks |
| `-ShowCriticalOnly` | Switch | Show only critical/high priority |
| `-Categories` | String[] | Filter by categories |
| `-Priority` | String | Filter by priority (Critical, High, Medium, Low) |

### Start-ESSDeployment.ps1
| Parameter | Type | Description |
|-----------|------|-------------|
| `-StartFromPhase` | Int (1-6) | Resume from specific phase |
| `-ResetProgress` | Switch | Clear saved progress |
| `-AutoFix` | Switch | Attempt automatic remediation |

### Invoke-ConnectivitySuite.ps1
| Parameter | Type | Description |
|-----------|------|-------------|
| `-ConfigFile` | String | Path to JSON config file |
| `-TestSuite` | String | Which tests to run (All, Workday, ServiceNow, etc.) |
| `-OutputPath` | String | Custom report output path |

---

## Report Locations

```
$HOME\Desktop\ESS-Reports\
├── ESS-Validation-YYYYMMDD-HHMMSS.html      (Full validation)
├── ESS-Connectivity-Report-*.html           (Connectivity tests)
├── Copilot-Agent-Test-*.json                (Agent quality)
└── Deployment\
    └── Phase-N-PhaseName-*.html             (Phase reports)

$HOME\.ess-validator\
├── profiles.json                             (Saved profiles)
└── deployment-state.json                     (Deployment progress)
```

---

## Keyboard Shortcuts (Interactive Menus)

### Phased Deployment Wizard
- `1-6` - Select specific phase
- `A` - Run all phases sequentially
- `R` - Reset progress
- `Q` - Quit

### Connectivity Test Suite
- `1` - Workday ISU
- `2` - Workday SSO
- `3` - ServiceNow
- `4` - SAP
- `5` - Copilot Agent
- `A` - Run all tests
- `W` - Run all Workday tests
- `Q` - Quit

---

## Status Indicators

### Phase Status
- ✓ Complete - Phase passed all checks
- 🔒 Blocked - Critical issues must be fixed
- ⏳ In Progress - Currently running
- ⚪ Not Started - Not yet run

### Checkpoint Status
- ✓ Passed - Check passed
- ✗ Failed - Check failed
- ⚠ Warning - Non-critical issue
- ○ Not Configured - Not yet configured

---

## Filtering Categories

Available categories for `-Categories` parameter:
- Prerequisites
- Environment
- Authentication
- ExternalSystems
- Content
- Topics
- Configuration
- Publishing
- Deployment

---

## Priority Levels

Available priorities for `-Priority` parameter:
- Critical - Must be fixed
- High - Should be fixed
- Medium - Nice to have
- Low - Optional

---

## Tips & Tricks

### 1. Save Time with Profiles
```powershell
# First run saves profile
.\Start-ESSValidation.ps1

# Subsequent runs load automatically
.\Start-ESSValidation.ps1  # Uses saved profile
```

### 2. Filter for Quick Reviews
```powershell
# Just show me what's broken
.\Start-ESSValidation.ps1 -ShowFailedOnly

# Critical items only
.\Start-ESSValidation.ps1 -Priority "Critical"
```

### 3. Automate with Config Files
```powershell
# Set up once
cp ConnectivityTests\config\prod-tests.json ConnectivityTests\config\mine.json
# Edit mine.json with credentials

# Run daily (can schedule as task)
cd ConnectivityTests
.\Invoke-ConnectivitySuite.ps1 -ConfigFile .\config\mine.json -TestSuite All
```

### 4. Export for Analysis
- Open HTML report
- Click "Export JSON" or "Export CSV"
- Analyze trends in Excel/PowerBI

### 5. Search Reports
- Open HTML report
- Use search box at top
- Search by checkpoint ID, result text, or remediation

---

## Troubleshooting

### "Module not found"
**Solution:** Ensure you're in the correct directory
```powershell
cd C:\ESS-PreFlight-Validator\PowerShell
```

### "Permission denied"
**Solution:** Run as administrator or grant permissions

### "Config file not found"
**Solution:** Check path to config file
```powershell
# Use full path
.\Invoke-ConnectivitySuite.ps1 -ConfigFile "C:\ESS-PreFlight-Validator\PowerShell\ConnectivityTests\config\prod-tests.json"
```

### "Environment not found"
**Solution:** Ensure you're connected to correct tenant
```powershell
# Reconnect
Connect-MgGraph -TenantId "your-tenant-id"
Add-PowerAppsAccount
```

### "Slow on first run"
**Solution:** Module loading optimization works after first run. First run takes 2-3 minutes, subsequent runs take 10-15 seconds.

---

## Get Help

### Built-in Help
```powershell
Get-Help .\Start-ESSValidation.ps1 -Full
Get-Help .\Start-ESSDeployment.ps1 -Examples
Get-Help .\Invoke-ConnectivitySuite.ps1 -Detailed
```

### Documentation
- `README-COMPLETE-SUITE.md` - Full technical documentation
- `LEADERSHIP-SUMMARY.md` - Executive summary
- `ARCHITECTURE.md` - System architecture
- `config\README.md` - Configuration guide

---

## Version Information

**Current Version:** 2.0.0  
**Release Date:** January 10, 2026  
**Status:** Production Ready

### What's New in v2.0
- ✨ Phased Deployment Wizard
- ✨ Connectivity Test Suite
- ✨ Enhanced HTML reports with search/filter/export
- ✨ Advanced filtering parameters
- ✨ Config file support

---

**Built with 🔥 and ☕**

For questions or feedback, contact your ESS deployment team!
