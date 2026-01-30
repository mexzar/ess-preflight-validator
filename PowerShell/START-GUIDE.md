# Start-ESSValidation.ps1 - User Guide

## Overview
Interactive wizard that makes ESS validation easy and personalized for your account.

## Quick Start

```powershell
cd C:\ESS-PreFlight-Validator\PowerShell
.\Start-ESSValidation.ps1
```

## Features

### ✅ Auto-Detection
- Detects your current user (admin@contoso.com)
- Finds your tenant ID automatically
- Remembers your last validation settings

### 💾 Profile Management
- Saves your preferences to: `$HOME\.ess-validator\profiles.json`
- Remembers:
  - Tenant ID
  - Environment selection
  - Agent name (Employee Self-Service)
  - Last used timestamp
- Keeps last 5 profiles automatically

### 🔐 Personal Permissions Check
Validates **YOUR** account has:
- Global Admin role
- Power Platform Admin role
- Copilot Studio/Power Apps licenses

### 🎨 Interactive Experience
- Environment picker (grid view)
- Smart defaults
- Progress indicators
- Color-coded results
- Auto-opens HTML report

### 📊 Report Management
- Saves to: `Desktop\ESS-Reports\`
- Filename: `ESS-Validation-YYYYMMDD-HHMMSS.html`
- Automatically opens in browser (optional)

## Parameters

### `-SkipProfile`
Skip loading saved profiles, start fresh

```powershell
.\Start-ESSValidation.ps1 -SkipProfile
```

### `-NoOpenReport`
Don't open the report automatically

```powershell
.\Start-ESSValidation.ps1 -NoOpenReport
```

## Usage Examples

### First-Time Use
```powershell
# Run wizard (will prompt for all settings)
.\Start-ESSValidation.ps1

# Wizard will ask:
# 1. Confirm tenant (or enter manually)
# 2. Select environment from grid
# 3. Confirm agent name (Employee Self-Service IT (Preview)Sandbox)
# 4. Check YOUR permissions
# 5. Run validation
# 6. Save profile for next time
```

### Subsequent Runs
```powershell
# Run with saved profile (fastest)
.\Start-ESSValidation.ps1

# Wizard will:
# 1. ✓ Load last profile automatically
# 2. ✓ Show saved settings
# 3. Ask if you want to use them [Y/n]
# 4. Run validation
```

### Cross-Tenant Testing
```powershell
# Force new tenant selection
.\Start-ESSValidation.ps1 -SkipProfile

# Enter different tenant ID when prompted
```

## What Gets Validated

Same comprehensive validation as ESS-Validator.psm1:
- Prerequisites (licenses, roles)
- Environment configuration
- Authentication setup
- External systems (ServiceNow for your agent)
- Content sources
- Topics
- Configuration
- Publishing readiness

## Sample Output

```
╔════════════════════════════════════════════════════════════════╗
║     ESS Pre-flight Deployment Validation Wizard v1.0           ║
║     Interactive validation for Employee Self-Service           ║
╚════════════════════════════════════════════════════════════════╝

✓ Detected user: admin@contoso.com
✓ Found saved profile: 'ESS_Production - 2026-01-30' (last used 2026-01-30 09:30:00)

Use saved profile? [Y/n]: Y

✓ Tenant: Contoso (31fcf92c...)
✓ Environment: ESS_Sandbox
✓ Agent: Employee Self-Service IT (Preview)Sandbox

🔐 Checking YOUR permissions...
  ✓ Global Admin: True
  ✓ Power Platform Admin: True
  ✓ Copilot Studio License: True

Run full validation? [Y/n]: Y

═══════════════════════════════════════════════════════════════
Starting Validation...
═══════════════════════════════════════════════════════════════

[██████████████████████████████████████████████████] 100% - Complete!

═══════════════════════════════════════════════════════════════
Validation Complete!
═══════════════════════════════════════════════════════════════

  Total Checks: 35
  ✓ Passed: 7
  ✗ Failed: 2
  ⚠  Warnings: 2
  ○ Not Configured: 24

🚨 Critical Issues Found:
   • PRE-002: No Copilot Studio licenses found for environment makers

📄 Report saved: C:\Users\YourUsername\Desktop\ESS-Reports\ESS-Validation-20260130-093000.html

Open report in browser? [Y/n]: Y

Thank you for using ESS Pre-flight Validator! 🚀
```

## Comparison with Manual Approach

| Task | Manual (ESS-Validator.psm1) | Wizard (Start-ESSValidation.ps1) |
|------|----------------------------|-----------------------------------|
| Commands to run | 5+ separate cmdlets | 1 script |
| Tenant ID | Copy/paste from portal | Auto-detected |
| Environment | Type exact ID | Pick from grid |
| Agent name | Remember exact name | Saved in profile |
| Permissions | Check manually | Automatic validation |
| Report location | Must specify path | Auto-saved to Desktop |
| Next run | Re-type everything | Load saved profile |

## Troubleshooting

### "ESS-Validator.psm1 not found"
Ensure both files are in the same directory:
```
C:\ESS-PreFlight-Validator\PowerShell\
  ├── ESS-Validator.psm1
  └── Start-ESSValidation.ps1
```

### "Unable to check permissions"
The wizard will continue even if permission checks fail. The full validation will still run.

### Profile not saving
Profile is saved to: `$HOME\.ess-validator\profiles.json`

Check if directory is writable:
```powershell
Test-Path (Join-Path $HOME ".ess-validator")
```

### Report not opening
Use `-NoOpenReport` parameter and manually open from:
```
Desktop\ESS-Reports\ESS-Validation-YYYYMMDD-HHMMSS.html
```

## Advanced Usage

### Run validation, save results, don't open browser
```powershell
.\Start-ESSValidation.ps1 -NoOpenReport
```

### Clear saved profiles
```powershell
Remove-Item "$HOME\.ess-validator\profiles.json"
```

### View saved profiles
```powershell
Get-Content "$HOME\.ess-validator\profiles.json" | ConvertFrom-Json
```

### Schedule weekly validation
Create scheduled task that runs:
```powershell
C:\ESS-PreFlight-Validator\PowerShell\Start-ESSValidation.ps1 -NoOpenReport
```

## Benefits Over Manual Validation

1. **Faster**: 1 command vs 5+
2. **Easier**: No parameter memorization
3. **Personalized**: Checks YOUR permissions
4. **Persistent**: Remembers your settings
5. **Professional**: Auto-saves organized reports
6. **Safer**: Progress indicators show status
7. **Flexible**: Works with saved profiles or fresh start

## Next Steps

After running validation:
1. Review critical issues in HTML report
2. Fix any failed checks (especially PRE-002)
3. Re-run wizard to verify fixes
4. Share report with stakeholders
5. Schedule regular validations (weekly recommended)

## See Also
- `ESS-Validator.psm1` - Core validation module
- `ValidationMatrix.md` - Complete checkpoint reference
- `Quick-Start-Guide.md` - Original setup guide
