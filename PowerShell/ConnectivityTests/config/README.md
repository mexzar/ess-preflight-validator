# ESS Connectivity Test Suite - Configuration Guide

## Overview
The ESS Connectivity Test Suite supports JSON configuration files for automated testing without manual credential entry. This guide explains how to set up and use configuration files.

## Configuration Files

### Provided Templates
- **prod-tests.json**: Production environment configuration
- **test-tests.json**: Test/Development environment configuration

### File Location
Place config files in: `C:\ESS-PreFlight-Validator\PowerShell\ConnectivityTests\config\`

## Configuration Structure

```json
{
  "description": "Human-readable description",
  "environment": "production|test",
  "workday": { ... },
  "servicenow": { ... },
  "sap": { ... },
  "copilot": { ... },
  "reporting": { ... },
  "notifications": { ... },
  "security": { ... }
}
```

## Section Details

### Workday Configuration
```json
"workday": {
  "tenant": "yourcompany",                    // Workday tenant name
  "isu": {
    "username": "ISU_User@tenant",           // Integration System User
    "password": "secure_password",           // ISU password
    "description": "ISU account description"
  },
  "sso": {
    "tenantId": "azure-ad-tenant-id",        // Azure AD tenant for SSO
    "description": "SSO configuration"
  }
}
```

**Required for:**
- Test-WorkdayConnectivity.ps1 (ISU)
- Test-WorkdaySSOConnectivity.ps1 (SSO)

### ServiceNow Configuration
```json
"servicenow": {
  "instance": "yourcompany",                 // Instance name (before .service-now.com)
  "username": "integration_user",            // ServiceNow username
  "password": "secure_password",             // ServiceNow password
  "oauth": {
    "clientId": "client_id",                 // OAuth client ID (optional)
    "clientSecret": "client_secret",         // OAuth client secret (optional)
    "enabled": false                         // Use OAuth instead of Basic auth
  }
}
```

**Required for:**
- Test-ServiceNowConnectivity.ps1

### SAP Configuration
```json
"sap": {
  "endpoint": "https://sap-gateway.com:8000/sap/opu/odata/sap/",
  "username": "SAP_USER",                    // SAP username
  "password": "secure_password",             // SAP password
  "client": "100"                            // SAP client number
}
```

**Required for:**
- Test-SAPConnectivity.ps1 (when implemented)

### Copilot Configuration
```json
"copilot": {
  "environmentId": "guid",                   // Power Platform environment ID
  "agentId": "cr123_agentname",             // Copilot agent ID
  "agentName": "ESS Agent",                 // Human-readable agent name
  "testScenarios": ["Basic", "HR", "IT"]    // Which test scenarios to run
}
```

**Required for:**
- Test-CopilotAgentResponse.ps1

### Reporting Configuration
```json
"reporting": {
  "outputPath": "C:\\ESS-Reports\\Production",  // Report output directory
  "includeDetailedLogs": true,                  // Include verbose logs
  "autoOpenReports": true                       // Auto-open HTML reports
}
```

### Notifications Configuration
```json
"notifications": {
  "emailOnFailure": true,                       // Send email on test failures
  "emailRecipients": ["email@company.com"],     // Email recipients
  "teamsWebhookUrl": "https://..."              // Teams webhook for notifications
}
```

### Security Configuration
```json
"security": {
  "encryptPasswords": true,                     // Encrypt passwords in config
  "useKeyVault": false,                         // Use Azure Key Vault for secrets
  "keyVaultName": "ess-keyvault"               // Azure Key Vault name
}
```

## Usage Examples

### Run with Config File
```powershell
# Use production config
.\Invoke-ConnectivitySuite.ps1 -ConfigFile .\config\prod-tests.json -TestSuite All

# Use test config for Workday tests only
.\Invoke-ConnectivitySuite.ps1 -ConfigFile .\config\test-tests.json -TestSuite Workday
```

### Run Without Config (Interactive)
```powershell
# Interactive mode - will prompt for credentials
.\Invoke-ConnectivitySuite.ps1 -TestSuite Interactive
```

### Individual Tests with Config
```powershell
# Run individual test scripts can also read config files in the future
# For now, they use interactive prompts
```

## Security Best Practices

### 1. Never Commit Credentials to Git
Add to `.gitignore`:
```
config/*-tests.json
*.credentials.json
```

### 2. Use Restricted File Permissions
```powershell
# Windows: Restrict config folder to admins only
icacls "C:\ESS-PreFlight-Validator\PowerShell\ConnectivityTests\config" /inheritance:r /grant:r "BUILTIN\Administrators:(OI)(CI)F"
```

### 3. Consider Azure Key Vault
For production, store secrets in Azure Key Vault:
1. Create Key Vault
2. Store secrets as Key Vault secrets
3. Update config to reference secrets (future enhancement)

### 4. Encrypt Passwords Locally
```powershell
# Example: Encrypt password using DPAPI (future enhancement)
$securePassword = ConvertTo-SecureString "Password123" -AsPlainText -Force
$encryptedPassword = ConvertFrom-SecureString $securePassword
# Store $encryptedPassword in config file
```

## Customization

### Add Custom Test Parameters
You can extend the config structure for custom tests:

```json
"custom": {
  "myTest": {
    "endpoint": "https://custom-system.com",
    "apiKey": "your-api-key"
  }
}
```

### Environment-Specific Configs
Create multiple configs for different environments:
- `prod-tests.json` - Production
- `test-tests.json` - Test/Dev
- `ppe-tests.json` - Pre-production
- `sandbox-tests.json` - Sandbox

## Troubleshooting

### Config File Not Found
```
✗ Config file not found: .\config\prod-tests.json
```
**Solution:** Ensure the file exists in the correct path

### Invalid JSON Format
```
✗ Failed to parse config file: Invalid JSON at line X
```
**Solution:** Validate JSON using a JSON validator or VS Code

### Missing Required Fields
```
⚠ Warning: Config missing 'workday.isu.username' - will prompt for input
```
**Solution:** Add missing fields to config file or provide interactively

## Support

For questions or issues with configuration:
1. Review this guide
2. Check the example templates
3. Contact ESS deployment team
4. Review connectivity test logs

## Version History

- **v1.0.0** (2026-01-10): Initial configuration structure
  - Workday (ISU/SSO) support
  - ServiceNow support
  - SAP support (placeholder)
  - Copilot agent support
  - Reporting and notification configs
