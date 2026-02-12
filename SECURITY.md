# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly:

1. **Do NOT** open a public GitHub Issue
2. Contact the maintainers privately
3. Provide details of the vulnerability
4. Allow reasonable time for a fix before public disclosure

## Security Best Practices

When using this tool:

### Authentication
- Use accounts with **least privilege** required for validation
- Consider using a dedicated service account for automated runs
- Review permissions granted during sign-in prompts

### Credentials
- Never save credentials in scripts or configuration files
- Use interactive authentication when possible
- Clear PowerShell history after sensitive operations:
  ```powershell
  Clear-History
  Remove-Item (Get-PSReadlineOption).HistorySavePath
  ```

### Reports
- Generated HTML/JSON reports may contain:
  - Environment names and IDs
  - User principal names
  - Configuration details
- Store reports securely
- Do not share reports publicly without sanitization

### Network
- Tool connects to:
  - Microsoft Graph API
  - Power Platform APIs
  - Copilot Studio APIs
  - Workday/ServiceNow endpoints (if configured)
- Ensure connections are over HTTPS
- Review firewall/proxy logs if required by your organization

## Dependencies

This tool uses:

| Module | Purpose |
|--------|---------|
| Microsoft.Graph.* | Entra ID and licensing checks |
| Microsoft.PowerApps.Administration.PowerShell | Power Platform validation |
| Microsoft.Xrm.Tooling.CrmConnector.PowerShell | Dataverse connectivity |

Keep modules updated for security patches:

```powershell
Update-Module Microsoft.Graph.* -Force
Update-Module Microsoft.PowerApps.Administration.PowerShell -Force
```

## Sensitive Data Handling

The tool does NOT:
- Store credentials locally
- Transmit data to external services (beyond required APIs)
- Collect telemetry or usage data

The tool DOES:
- Cache authentication tokens (per Microsoft standard)
- Generate local reports with environment data
- Query your Microsoft 365 tenant for license/config info

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.7.x   | ✅ Yes    |
| 1.6.x   | ⚠️ Limited |
| < 1.6   | ❌ No     |

---

For general questions, open a GitHub Issue. For security concerns, contact maintainers directly.
