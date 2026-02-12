# Pre-flight Deployment Validator for Employee Self-Service (ESS) Agent

## 🚀 Quick Start

### Download

**[Download Latest Release](../../releases/latest)** - Get the ready-to-run `ESS-Validator.exe`

| Asset | Description |
|-------|-------------|
| `ESS-Validator.exe` | Double-click launcher - no installation required |
| `Source code (zip)` | Full PowerShell scripts for customization |

### Requirements
- Windows 10/11 or Windows Server 2019+
- PowerShell 7.x (installer included if needed)
- Microsoft 365 admin credentials for validation

### Run It
1. Download `ESS-Validator.exe` from the latest release
2. Double-click to launch
3. Follow the menu to run validations

> **Note**: Windows SmartScreen may prompt on first run. Click "More info" → "Run anyway" (the exe is unsigned open source software).

---

## Overview

This solution provides comprehensive validation capabilities to assess deployment readiness for the Microsoft 365 Copilot Employee Self-Service agent before production deployment.

## Solution Components

### 1. Power Platform Validation Solution
- **Power Automate Flows**: Automated validation checks for environment readiness, authentication, and connectivity
- **Copilot Studio Topics**: Interactive validation reporting and guidance
- **Dataverse Tables**: Validation results storage and tracking
- **Custom Connectors**: External system connectivity verification

### 2. PowerShell Validation Module
- **ESS-Validator.psm1**: Comprehensive PowerShell cmdlets for command-line validation
- **Validation Reports**: JSON/HTML formatted validation results
- **Automated Remediation**: Suggested fixes for common issues

### 3. Workday Validation Suite
Standalone tools for deep Workday integration testing:

| Tool | Purpose |
|------|---------|
| **Test-WorkdayWorkflows.ps1** | Tests ALL 17 ESS pre-configured workflows via SOAP API |
| **Test-WorkdaySSOConnectivity.ps1** | OAuth Device Code Flow testing for SSO validation |
| **Test-WorkdaySSOConfiguration.ps1** | Validates 4 required Power Platform connections |
| **Test-WorkdayConnectivity.ps1** | Basic endpoint and auth validation |

### 4. Connectivity Test Suite
- **Invoke-ConnectivitySuite.ps1**: Orchestrates all connectivity tests
- **Test-CopilotAgentResponse.ps1**: Validates Copilot Studio agent responses
- **Test-ServiceNowConnectivity.ps1**: ServiceNow HRSD/ITSM validation

## Validation Coverage

### Prerequisites Validation
- Licensing (Microsoft 365 Copilot, Copilot Studio, Teams)
- Capacity planning (Pay-As-You-Go, prepaid messages)
- Role assignments (Global Admin, Power Platform Admin, Environment Maker)
- Power Platform environment configuration

### Authentication Validation
- Microsoft Entra ID configuration
- Single Sign-On (SSO) setup
- OAuth 2.0/OIDC configurations
- Certificate-based authentication
- Federation validation

### External Systems Integration
- **SAP SuccessFactors**: OData v2.0 connectivity, OAuth setup, template validation
- **Workday**: SOAP/RaaS endpoints, authentication, template configurations
- **ServiceNow**: Knowledge connector, HRSD/ITSM, Live Agent integration

### Workday Security Domains
The validator documents required permissions for all ESS workflows:

**Read Workflows (15)** - Security Domain `Self-Service: [Domain] as Self`:
| Workflow | Domain | PII |
|----------|--------|-----|
| Employee ID | Worker Profile | |
| Company Code | Organizations | |
| Cost Center | Organizations | |
| Hire Date | Worker Profile | |
| Employment Info | Worker Profile | |
| Position Number | Worker Profile | |
| Service Anniversary | Worker Profile | |
| National IDs | Personal Data | ⚠️ |
| Passports | Personal Data | ⚠️ |
| Visas | Personal Data | ⚠️ |
| Language Info | Worker Profile | |
| Certifications | Qualifications | |
| Base Compensation | Compensation | |
| Compensation Ratio | Compensation | |
| Emergency Contact | Personal Data | ⚠️ |

**Write Workflows (2)** - Security Domain `Self-Service: [Domain] as Self`:
| Workflow | Domain |
|----------|--------|
| Update Email | Contact Information |
| Update Phone | Contact Information |

**ISU Service Account Domains (9)**:
- ISU_WQL_COPILOT: Workday Accounts, Custom Report Creation, Person Data: Work Email, Worker Data: Current Staffing Info, Worker Data: Worker ID, Setup: Tenant Setup - Reporting
- ISU_Generic_COPILOT: Integration Build, Job Information, Setup: Compensation Packages

### Content Validation
- SharePoint knowledge sources optimization
- Semantic indexing limits (200 pages)
- Metadata and permissions structure
- Advanced filtering configuration (KQL)

### Configuration Validation
- Topics configuration (Admin, System, Example topics)
- Agent instructions and personality
- User Context variables
- Environment variables
- Starter prompts
- Branding and customization

### Publishing Validation
- ALM process validation
- Solution export/import readiness
- Golden prompt testing framework
- Channel configuration (Teams, Microsoft 365 Copilot)
- Admin approval workflow

## Deployment Validation Stages

### Stage 1: Environment Preparation
✓ Power Platform environment creation  
✓ Dataverse database enabled  
✓ Copilot Studio capacity configured  
✓ DLP policies reviewed  
✓ IP allowlisting for external systems  

### Stage 2: Prerequisites Check
✓ License assignments verified  
✓ Required roles assigned  
✓ Capacity planning completed  
✓ Authentication architecture defined  

### Stage 3: Installation Readiness
✓ Preferred solution created  
✓ Environment selected  
✓ ESS agent starter chosen (HR/IT)  
✓ Installation checklist completed  

### Stage 4: Configuration Validation
✓ Topics customized and tested  
✓ Knowledge sources configured  
✓ External system connections established  
✓ User Context setup completed  
✓ Instructions and branding applied  

### Stage 5: Publishing Readiness
✓ Golden prompts tested  
✓ Quality benchmarks met  
✓ ALM process validated  
✓ Admin approval obtained  
✓ Channel deployment configured  

## Known Limitations Check

The validator verifies awareness of 48+ documented limitations including:
- Mobile support (pending 2026)
- Publishing delays (up to 48 hours)
- Semantic indexing limits (~200 pages)
- External system integration complexity
- Teams channel specific issues
- Content handling constraints

## Usage

### Power Platform Solution
1. Import managed solution into target environment
2. Configure validation flow parameters
3. Run validation from Copilot Studio interface
4. Review validation results in Dataverse

### PowerShell Module
```powershell
# Import the module
Import-Module .\ESS-Validator.psm1

# Run comprehensive validation
Test-ESSDeploymentReadiness -Verbose

# Individual validation checks
Test-ESSPrerequisites
Test-ESSAuthentication
Test-ESSExternalSystems
Test-ESSContentReadiness
Test-ESSConfiguration
Test-ESSPublishingPrerequisites
```

### Workday Workflow Testing
Test all 17 ESS pre-configured workflows directly against Workday SOAP APIs:
```powershell
# Test all workflows with Basic Auth
.\Test-WorkdayWorkflows.ps1

# Skip write tests in production (safe mode)
.\Test-WorkdayWorkflows.ps1 -SkipWriteTests
```

**Workflows Tested:**
- **Read (15)**: Employee ID, Company Code, Cost Center, Hire Date, Employment Info, Position Number, Service Anniversary, National IDs, Passports, Visas, Language Info, Certifications, Base Compensation, Compensation Ratio, Emergency Contact
- **Write (2)**: Update Email, Update Phone

**Example Output:**
```
Testing Employee ID... [PASS]
Testing Company Code... [PASS]
Testing Compensation... [FAIL] Permission Denied
Testing Emergency Contact... [PASS*] (API works, no data found)
```

### Workday SSO Configuration
Validate the 4 required Power Platform connections:
```powershell
# Interactive mode (prompts for each connection)
.\Test-WorkdaySSOConfiguration.ps1 -EnvironmentId "your-env-id"

# Non-interactive mode (for automation)
.\Test-WorkdaySSOConfiguration.ps1 -EnvironmentId "your-env-id" `
    -OAuthUserConnection "oauth user" `
    -ISUWQLConnection "isu wql entra" `
    -ISUGenericConnection "isu generic entra" `
    -SkipPrompts
```

### Workday SSO Connectivity
Test OAuth Device Code Flow with Entra ID:
```powershell
# Requires: Entra ID Enterprise App with API permissions configured
.\Test-WorkdaySSOConnectivity.ps1

# Script prompts for:
# - Tenant ID
# - Client ID (Enterprise App)
# - App ID URI (from Workday Enterprise App)
```

**Prerequisites for SSO Testing:**
1. Workday Enterprise App registered in Entra ID
2. API permissions granted (requires Entra Admin)
3. App ID URI configured (typically: `https://wd2-impl-services1.workday.com/<tenant>`)

### Copilot Agent Testing
```powershell
# Test agent responses
.\Test-CopilotAgentResponse.ps1 -EnvironmentId "your-env-id" -AgentName "ESS Agent"
```

### ServiceNow Connectivity
```powershell
# Validate ServiceNow integration
.\Test-ServiceNowConnectivity.ps1 -InstanceUrl "https://yourinstance.service-now.com"
```

## Validation Report Output

Each validation produces:
- **Status**: Pass/Fail/Warning/Not Configured
- **Priority**: Critical/High/Medium/Low
- **Category**: Prerequisites/Authentication/External Systems/Content/Configuration/Publishing
- **Details**: Specific findings and recommendations
- **Remediation**: Step-by-step fix instructions
- **Documentation Links**: Relevant Microsoft Learn articles

## Quality Assurance Integration

The validator implements the recommended Golden Prompt Testing Framework:
- Curated test scenarios covering critical workflows
- Known expected responses validation
- Core functionality regression testing
- Edge case coverage

## Capacity Planning Support

Validates configuration against documented usage patterns:
- Sample benchmarks (MAU, conversations, interactions)
- Cost estimation for Pay-As-You-Go users
- LLM compute scenarios identification
- Prepaid message capacity verification

## Responsible AI Validation

Verifies implementation of:
- Sensitive topics configuration
- Emotional intelligence (EQ) topic
- Ambiguity clarification topic
- Content filtering and RAI boundaries
- Escalation pathways

## Documentation References

All validation checks reference specific Microsoft Learn documentation:
- Prerequisites: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/prerequisites
- Deployment Overview: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/deploy-overview-alm
- Installation: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/install
- Customization: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/customize
- Publishing: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/publish
- Known Issues: https://learn.microsoft.com/en-us/copilot/microsoft-365/employee-self-service/known-issues-limitations

## Support

For questions or issues:
1. Review validation error details and remediation guidance
2. Consult Microsoft Learn documentation links provided
3. Check known issues and limitations documentation
4. Contact your Power Platform administrator

## Version History

- **v1.5.0** - Workday Workflow Testing
  - NEW: `Test-WorkdayWorkflows.ps1` - Tests ALL 17 ESS workflows via SOAP API
  - Tests 15 Read workflows + 2 Write workflows with [PASS]/[FAIL] output
  - `-SkipWriteTests` flag for production safety
  - Identifies which security domains need to be granted

- **v1.4.1** - SSO Configuration UX Overhaul
  - `Test-WorkdaySSOConfiguration.ps1` v2.0 - Prompt-and-confirm approach
  - Auto-detects 4 required connections, lets you confirm or correct
  - New CLI parameters for automation (`-SkipPrompts`, connection name params)

- **v1.4.0** - SSO Security Domain Documentation
  - NEW: `Test-WorkdaySSOConfiguration.ps1` - Deep SSO diagnostic tool
  - Documents all 17 ESS workflows with required Workday security domains
  - Generates printable checklist for Workday Administrator
  - PII flagging for sensitive data (National IDs, Passports, Visas, Emergency Contacts)

- **v1.3.1** - Agent Selection & Output Improvements
  - Simplified agent selection UX (2 options vs 4)
  - Enhanced CA Policy output (shows actual policy names)
  - Enhanced ServiceNow flow listing (HRSD/ITSM grouping)
  - Standalone WorkdaySuite execution via dot-sourcing
  - Fixed flow matching bug for ESS patterns

- **v1.3.0** - Workday SOAP Testing
  - NEW: `Test-WorkdayConnectivity.ps1` - Endpoint and auth validation
  - NEW: `Test-WorkdaySSOConnectivity.ps1` - OAuth Device Code Flow testing
  - NEW: `Test-WorkdayConnectionReferences.ps1` - Validates 19 connection references

- **v1.2.0** - Connectivity Test Suite
  - Added `ConnectivityTests/` folder structure
  - Config-driven testing (`prod-tests.json`, `test-tests.json`)
  - `Test-CopilotAgentResponse.ps1` for agent validation
  - `Test-ServiceNowConnectivity.ps1` for HRSD/ITSM

- **v1.0.0** - Initial release with comprehensive validation coverage for ESS deployment
