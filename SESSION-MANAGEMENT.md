# Session Management Guide

## End of Session Checklist

When you're done working and want to save your progress:

### 1. **Test Everything Works**
```powershell
cd C:\ESS-PreFlight-Validator\PowerShell

# Test main scripts still work
.\Start-ESSValidation.ps1 -SkipProfiles
.\Start-ESSDeployment.ps1 -ResetProgress
```

### 2. **Review What Changed**
```powershell
cd C:\ESS-PreFlight-Validator

# See what files changed
git status

# See detailed changes
git diff

# Review specific file changes
git diff PowerShell/ESS-Validator.psm1
```

### 3. **Commit Changes**
```powershell
# Add all changes
git add .

# Commit with clear message
git commit -m "Brief description of what you changed"

# Example:
git commit -m "Fixed ENV-003 and ENV-008 error messages for better UX"
```

### 4. **Create Versioned Backup**
```powershell
# Create backup (saves to Desktop with timestamp)
.\Create-Backup.ps1

# Backup includes all scripts, modules, and documentation
# Format: ESS-PreFlight-Validator-v1.1.0-YYYYMMDD-HHMMSS.zip
```

### 5. **Document Changes (if significant)**
```powershell
# Edit CHANGELOG.md to add your changes
code CHANGELOG.md

# Add entry under current version or create new version section
```

### 6. **Verify Backup Created**
```powershell
# Check latest backup on Desktop
Get-ChildItem "$HOME\Desktop\ESS-PreFlight-Validator-*.zip" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1 Name, LastWriteTime, Length
```

---

## Start of Session Checklist

When you start a new session:

### 1. **Check Current State**
```powershell
cd C:\ESS-PreFlight-Validator

# Check current version
type VERSION.txt

# View recent commits
git log --oneline -5

# Check for uncommitted changes
git status
```

### 2. **Review Recent Changes**
```powershell
# See what changed in last session
git log -1 --stat

# Read changelog
type CHANGELOG.md | Select-Object -First 50
```

### 3. **Create Pre-Session Backup** (optional but recommended)
```powershell
# Backup before making new changes
.\Create-Backup.ps1
```

### 4. **Test Current State**
```powershell
cd PowerShell

# Quick validation test
.\Start-ESSValidation.ps1 -SkipProfiles

# Or just test module loads
Import-Module .\ESS-Validator.psm1 -Force -WarningAction SilentlyContinue
Get-Command -Module ESS-Validator
```

---

## When You're Happy with a Stable Version

### Create an Official Release

```powershell
cd C:\ESS-PreFlight-Validator

# Use the automated script
.\Update-Version.ps1 -NewVersion "1.2.0" -Message "Production-ready with feature X"

# This will:
# 1. Create backup of current version
# 2. Update VERSION.txt
# 3. Commit changes
# 4. Create Git tag
```

### Manual Release Process

```powershell
# 1. Update VERSION.txt
code VERSION.txt
# Change: VERSION=1.2.0
#         RELEASE_DATE=2026-01-10
#         BUILD=20260110-120000

# 2. Update CHANGELOG.md
code CHANGELOG.md
# Add new version section with all changes

# 3. Create final backup
.\Create-Backup.ps1

# 4. Commit and tag
git add .
git commit -m "v1.2.0 - Production release"
git tag -a "v1.2.0" -m "Release v1.2.0"

# 5. View all versions
git tag
```

---

## Emergency: Need to Restore

### Restore from Git (recent changes)
```powershell
cd C:\ESS-PreFlight-Validator

# Undo uncommitted changes to specific file
git checkout -- PowerShell/ESS-Validator.psm1

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Go back to specific version
git checkout v1.1.0
```

### Restore from Backup ZIP
```powershell
# Find backups
Get-ChildItem "$HOME\Desktop\ESS-PreFlight-Validator-*.zip" | 
    Sort-Object LastWriteTime -Descending

# Restore specific backup
$backupPath = "C:\Users\...\ESS-PreFlight-Validator-v1.1.0-20260110-115027.zip"
$restorePath = "C:\ESS-PreFlight-Validator-Restored"

Expand-Archive $backupPath -DestinationPath $restorePath -Force

# Copy files back
Copy-Item "$restorePath\PowerShell\*" "C:\ESS-PreFlight-Validator\PowerShell\" -Force
```

---

## Daily Workflow Summary

### **Quick Daily Workflow:**

```powershell
# START OF DAY
cd C:\ESS-PreFlight-Validator
git status                  # Check state
.\Create-Backup.ps1         # Create backup

# DURING WORK
# ... make changes ...
# ... test frequently ...

# END OF DAY (when happy)
git add .                   # Stage changes
git commit -m "Summary"     # Commit
.\Create-Backup.ps1         # Final backup
```

### **Weekly Workflow:**

```powershell
# Review changes
git log --oneline --since="7 days ago"

# Clean up old backups (keep last 5)
Get-ChildItem "$HOME\Desktop\ESS-PreFlight-Validator-*.zip" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -Skip 5 | 
    Remove-Item -Confirm
```

### **When Releasing New Version:**

```powershell
# Automated way
.\Update-Version.ps1 -NewVersion "X.Y.Z" -Message "Release notes"

# Or manual
.\Create-Backup.ps1
# Update VERSION.txt and CHANGELOG.md
git add .
git commit -m "vX.Y.Z - Release"
git tag -a "vX.Y.Z" -m "Release vX.Y.Z"
```

---

## Key Files to Never Lose

These files contain your core work:

**Critical:**
- `PowerShell/ESS-Validator.psm1` (1,200+ lines - main engine)
- `PowerShell/Start-ESSValidation.ps1` (700+ lines - main wizard)
- `PowerShell/Start-ESSDeployment.ps1` (900+ lines - deployment wizard)

**Important:**
- `Documentation/*.md` (all guides)
- `VERSION.txt` (version tracking)
- `CHANGELOG.md` (change history)

**Protected by:**
- ✅ Git repository (`.git/` folder)
- ✅ Versioned backups (Desktop)
- ✅ Backup log (`backup-log.txt`)

---

## Safety Checks

### Before Major Changes
```powershell
# 1. Create backup
.\Create-Backup.ps1

# 2. Create feature branch (optional)
git checkout -b feature/my-new-feature

# 3. Test current state works
cd PowerShell
.\Start-ESSValidation.ps1 -SkipProfiles
```

### After Major Changes
```powershell
# 1. Test everything
cd PowerShell
.\Start-ESSValidation.ps1
.\Start-ESSDeployment.ps1

# 2. Review all changes
cd ..
git diff

# 3. Commit if good
git add .
git commit -m "Description"

# 4. Create backup
.\Create-Backup.ps1

# 5. Merge feature branch (if used)
git checkout master
git merge feature/my-new-feature
```

---

## Red Flags - Stop and Backup

**Immediately create backup if you see:**
- ❌ Module import errors
- ❌ "Function not recognized" errors
- ❌ Syntax errors after editing
- ❌ Reports not generating
- ❌ Git shows 500+ line changes you don't recognize

**Recovery steps:**
1. Don't panic
2. Don't save more changes
3. Run: `git diff > changes.txt` to save what you have
4. Restore from last backup or: `git checkout HEAD -- <file>`
5. Review `changes.txt` to see what broke

---

## Best Practices

✅ **DO:**
- Commit after each logical change
- Test before committing
- Create backup before experiments
- Use clear commit messages
- Update CHANGELOG for significant changes
- Keep last 5 backups on Desktop

❌ **DON'T:**
- Edit files outside Git repository
- Make changes without backups
- Commit broken code
- Delete backups without checking
- Skip testing after changes
- Use vague commit messages like "updates"

---

## Quick Reference Commands

```powershell
# Status check
git status
git log --oneline -5

# Create backup
.\Create-Backup.ps1

# Commit workflow
git add .
git commit -m "Clear message"

# New version
.\Update-Version.ps1 -NewVersion "X.Y.Z" -Message "Summary"

# Undo changes
git checkout -- <file>          # Undo file changes
git reset --soft HEAD~1         # Undo last commit, keep changes
git checkout v1.1.0             # Go to specific version

# View backups
Get-ChildItem "$HOME\Desktop\ESS-PreFlight-Validator-*.zip" | 
    Sort-Object LastWriteTime -Descending
```

---

## Summary

**At end of every session:**
1. ✅ Test scripts work
2. ✅ Commit changes (`git commit`)
3. ✅ Create backup (`.\Create-Backup.ps1`)

**At start of every session:**
1. ✅ Check status (`git status`)
2. ✅ Review recent changes (`git log`)
3. ✅ Create pre-session backup (optional)

**When releasing stable version:**
1. ✅ Run `.\Update-Version.ps1`
2. ✅ Update CHANGELOG.md
3. ✅ Create final backup
4. ✅ Tag release in Git

**You now have multiple safety nets:**
- Git history (every commit)
- Versioned backups (timestamped ZIPs)
- Tagged releases (v1.1.0, v1.2.0, etc.)
