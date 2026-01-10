# Version Control & Change Management Guide

## Quick Reference

### Daily Workflow

```powershell
# Check status
git status

# View uncommitted changes
git diff

# Create backup before changes
.\Create-Backup.ps1

# After making changes, commit
git add .
git commit -m "Description of changes"
```

### Creating a New Release

```powershell
# Use the automated script
.\Update-Version.ps1 -NewVersion "1.2.0" -Message "Added new features"

# Or manually:
# 1. Create backup
.\Create-Backup.ps1

# 2. Update VERSION.txt and CHANGELOG.md

# 3. Commit and tag
git add .
git commit -m "v1.2.0 - Description"
git tag -a "v1.2.0" -m "Release v1.2.0"
```

### Viewing History

```powershell
# View commit history
git log --oneline

# View specific file history
git log -- PowerShell/ESS-Validator.psm1

# View changes in a commit
git show <commit-hash>

# View all tags (versions)
git tag
```

### Rolling Back Changes

```powershell
# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Restore from backup
Expand-Archive "ESS-PreFlight-Validator-v1.1.0-*.zip" -DestinationPath ".\Restore"
```

### Before Making Changes Checklist

- [ ] Check current version: `type VERSION.txt`
- [ ] Review recent commits: `git log --oneline -5`
- [ ] Create backup: `.\Create-Backup.ps1`
- [ ] Create feature branch (optional): `git checkout -b feature/my-feature`
- [ ] Test current code works

### After Making Changes Checklist

- [ ] Test all affected scripts
- [ ] Update inline comments
- [ ] Run validation: `.\Start-ESSValidation.ps1`
- [ ] Update CHANGELOG.md if significant changes
- [ ] Commit with clear message
- [ ] Create backup if stable: `.\Create-Backup.ps1`

## File Structure

```
ESS-PreFlight-Validator/
├── .git/                    # Git repository (version history)
├── .gitignore              # Files to exclude from Git
├── VERSION.txt             # Current version info
├── CHANGELOG.md            # Detailed change history
├── Create-Backup.ps1       # Backup creation script
├── Update-Version.ps1      # Version update automation
├── backup-log.txt          # Backup history (auto-generated)
├── PowerShell/             # Main scripts
├── Documentation/          # Markdown documentation
└── README.md               # Project overview
```

## Key Files to Track

**Always commit:**
- PowerShell/*.ps1 (main scripts)
- PowerShell/*.psm1 (modules)
- Documentation/*.md
- VERSION.txt
- CHANGELOG.md

**Never commit:**
- User profiles (profiles.json)
- Generated reports (ESS-Reports/)
- Credentials/secrets
- Backup ZIP files
- Temporary files

## Semantic Versioning

Format: **MAJOR.MINOR.PATCH** (e.g., 1.2.3)

- **MAJOR** (1.x.x): Breaking changes, major rewrites
- **MINOR** (x.2.x): New features, non-breaking changes
- **PATCH** (x.x.3): Bug fixes, minor improvements

Examples:
- `1.0.0` → `1.1.0`: Added new validation checkpoints
- `1.1.0` → `1.1.1`: Fixed error message formatting
- `1.1.1` → `2.0.0`: Complete rewrite of module structure

## Common Commands

```powershell
# Show version info
type VERSION.txt

# List all backups
Get-ChildItem "$HOME\Desktop\ESS-PreFlight-Validator-*.zip" | Sort-Object LastWriteTime -Descending

# Compare two versions
git diff v1.0.0 v1.1.0

# Restore specific file from version
git checkout v1.0.0 -- PowerShell/ESS-Validator.psm1

# View what changed in a version
git show v1.1.0
```

## Troubleshooting

### "Module corrupted after edit"
```powershell
# Restore from Git
git checkout HEAD -- PowerShell/ESS-Validator.psm1

# Or restore from backup
Expand-Archive "ESS-PreFlight-Validator-v1.1.0-*.zip" -DestinationPath ".\Restore"
Copy-Item ".\Restore\PowerShell\ESS-Validator.psm1" ".\PowerShell\"
```

### "Lost unsaved changes"
```powershell
# Git can't help with uncommitted changes
# Always commit or create backup before major edits
```

### "Need to test old version"
```powershell
# Checkout old version (creates detached HEAD)
git checkout v1.0.0

# When done testing
git checkout master
```

## Best Practices

1. **Commit early, commit often** - Small, logical commits are easier to track
2. **Clear commit messages** - Describe WHAT changed and WHY
3. **Backup before experiments** - Use `Create-Backup.ps1` before risky changes
4. **Test before committing** - Ensure code works before committing
5. **Update CHANGELOG** - Keep users informed of changes
6. **Tag stable releases** - Makes it easy to find production versions

## Resources

- [Git Basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)

---

**Quick Help:**
- Create backup: `.\Create-Backup.ps1`
- Update version: `.\Update-Version.ps1 -NewVersion "X.Y.Z" -Message "..."`
- View history: `git log --oneline`
- Undo changes: `git checkout -- <file>`
