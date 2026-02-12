# Contributing to ESS Pre-Flight Validator

Thank you for your interest in contributing to the ESS Pre-Flight Validator!

## How to Contribute

### Reporting Issues

1. **Check existing issues** - Search open issues to avoid duplicates
2. **Use the issue template** - Provide:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Tool version (check `VERSION.txt`)
   - PowerShell version (`$PSVersionTable.PSVersion`)
   - Error messages (sanitized - no tenant/user info)

### Requesting Features

1. Open a GitHub Issue with the label `enhancement`
2. Describe the use case and expected behavior
3. If possible, suggest an implementation approach

### Submitting Code

1. **Fork** the repository
2. **Create a branch** for your feature/fix: `git checkout -b feature/my-feature`
3. **Make changes** following our coding standards (below)
4. **Test** your changes thoroughly
5. **Submit a Pull Request** with a clear description

## Coding Standards

### PowerShell

- Use approved verbs: `Get-`, `Set-`, `Test-`, `Invoke-`
- Include comment-based help for all functions
- Use `[CmdletBinding()]` for advanced functions
- Handle errors gracefully with `try/catch`
- Follow [PowerShell Best Practices](https://poshcode.gitbook.io/powershell-practice-and-style/)

### Example Function Structure

```powershell
function Test-ExampleValidation {
    <#
    .SYNOPSIS
        Brief description of what the function does.
    
    .DESCRIPTION
        Detailed description with context.
    
    .PARAMETER EnvironmentId
        The Power Platform environment ID to validate.
    
    .EXAMPLE
        Test-ExampleValidation -EnvironmentId "00000000-0000-0000-0000-000000000000"
    
    .OUTPUTS
        PSCustomObject with validation results
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$EnvironmentId
    )
    
    try {
        # Implementation
    }
    catch {
        Write-Error "Validation failed: $($_.Exception.Message)"
    }
}
```

### Documentation

- Update README.md if adding new features
- Update CHANGELOG.md following Keep a Changelog format
- Add inline comments for complex logic

## Security Guidelines

**DO NOT include in commits:**
- Tenant IDs, environment IDs, or GUIDs from real environments
- Usernames, email addresses, or UPNs
- API keys, secrets, or tokens
- Customer names or organization identifiers
- Internal URLs or endpoints
- Screenshots with identifying information

**Use placeholders like:**
- `your-tenant.onmicrosoft.com`
- `your-instance.service-now.com`
- `00000000-0000-0000-0000-000000000000`
- `user@example.com`

## Testing Checklist

Before submitting a PR, verify:

- [ ] Works with PowerShell 7.x
- [ ] No hardcoded sensitive values
- [ ] Error handling is in place
- [ ] Functions have help documentation
- [ ] Changes tested against a test/demo environment
- [ ] CHANGELOG.md updated

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow

## Questions?

Open a GitHub Issue with the label `question`.

---

Thank you for helping improve the ESS Pre-Flight Validator! 🚀
