# ESS Pre-flight Deployment Validation Checklists

## Executive Deployment Readiness Checklist

Use this high-level checklist to track overall deployment readiness across all validation categories.

| Category | Critical Items | Status | Notes |
|----------|---------------|--------|-------|
| **Prerequisites** | ☐ M365 Copilot licenses assigned<br>☐ Copilot Studio licenses for makers<br>☐ Required roles assigned<br>☐ Capacity planning completed | ☐ Ready<br>☐ In Progress<br>☐ Blocked | |
| **Environment** | ☐ Power Platform environment created<br>☐ Dataverse database enabled<br>☐ DLP policies configured<br>☐ ALM strategy defined | ☐ Ready<br>☐ In Progress<br>☐ Blocked | |
| **Authentication** | ☐ Entra ID configured<br>☐ SSO setup completed<br>☐ User sync validated | ☐ Ready<br>☐ In Progress<br>☐ Blocked | |
| **External Systems** | ☐ SAP/Workday/ServiceNow packages installed<br>☐ Connectivity tested<br>☐ OAuth/Auth configured | ☐ Ready<br>☐ In Progress<br>☐ Blocked | |
| **Content** | ☐ Knowledge sources configured<br>☐ SharePoint permissions verified<br>☐ Indexing limits checked | ☐ Ready<br>☐ In Progress<br>☐ Blocked | |
| **Topics** | ☐ Required topics configured<br>☐ Custom topics created<br>☐ Trigger phrases tested | ☐ Ready<br>☐ In Progress<br>☐ Blocked | |
| **Configuration** | ☐ Agent branding applied<br>☐ Instructions written<br>☐ Starter prompts configured<br>☐ Variables defined | ☐ Ready<br>☐ In Progress<br>☐ Blocked | |
| **Testing** | ☐ Golden prompts created (50+)<br>☐ Quality benchmarks met<br>☐ UAT completed | ☐ Ready<br>☐ In Progress<br>☐ Blocked | |
| **Publishing** | ☐ Solution exported<br>☐ Test deployment successful<br>☐ Admin approval obtained<br>☐ Channels configured | ☐ Ready<br>☐ In Progress<br>☐ Blocked | |

**Overall Deployment Readiness:** ☐ GO ☐ NO GO

**Deployment Date:** ________________

**Approver:** ________________ **Date:** ________________

---

## Prerequisites Detailed Checklist

### Licensing Requirements

| Checkpoint | Requirement | Validation Method | Status | Notes |
|------------|-------------|-------------------|--------|-------|
| **Users** | Microsoft 365 Copilot licenses | Check license assignments in M365 Admin Center | ☐ | |
| **Makers/Admins** | Copilot Studio licenses | Check license assignments in M365 Admin Center | ☐ | |
| **Users** | Microsoft Teams licenses | Check license assignments in M365 Admin Center | ☐ | |
| **Environment** | Copilot Studio capacity configured | Verify in Power Platform Admin Center | ☐ | |
| **Pay-As-You-Go** | PayG or prepaid messages | Check billing configuration in PPAC | ☐ | |

### Role Assignments

| Role | Required For | Users Assigned | Verified |
|------|-------------|----------------|----------|
| Global Administrator | Assign Power Platform Admin role | | ☐ |
| Power Platform Administrator | Create environments, assign roles | | ☐ |
| Environment Maker | Configure ESS agent | | ☐ |
| External System Administrators | Provide SAP/Workday/ServiceNow configs | | ☐ |
| Information Security | Allowlist endpoints, manage SSO | | ☐ |

### Capacity Planning

| Item | Value/Status | Validated |
|------|-------------|-----------|
| Estimated MAU (Monthly Active Users) | __________ | ☐ |
| Average conversations per user | __________ | ☐ |
| Average interactions per conversation | __________ | ☐ |
| Cost per query for non-Copilot users | ~$0.15 | ☐ |
| PayG configured (if needed) | ☐ Yes ☐ No | ☐ |
| Prepaid messages purchased (if needed) | __________ messages | ☐ |

---

## Environment Configuration Checklist

### Power Platform Environment

| Checkpoint | Requirement | Status | Notes |
|------------|-------------|--------|-------|
| Environment created | Dev/Test/Prod environments exist | ☐ | |
| Dataverse database | Enabled and provisioned | ☐ | |
| Environment type | Managed environment (recommended) | ☐ | |
| Release cycle | Standard release | ☐ | |
| Copilot Studio access | Can access from environment | ☐ | |
| Preferred solution | Unmanaged solution created for Dev | ☐ | |
| Solution publisher | Publisher with prefix configured | ☐ | |

### Data Loss Prevention (DLP)

| Connector | DLP Group | Status | Notes |
|-----------|-----------|--------|-------|
| SharePoint | Business | ☐ | |
| SAP SuccessFactors (if used) | Business | ☐ | |
| Workday (if used) | Business | ☐ | |
| ServiceNow (if used) | Business | ☐ | |
| Microsoft Dataverse | Business | ☐ | |
| Office 365 Users | Business | ☐ | |

### ALM Strategy

| Item | Status | Notes |
|------|--------|-------|
| Development environment | ☐ | |
| Test/UAT environment | ☐ | |
| Production environment | ☐ | |
| Source control configured | ☐ | |
| CI/CD pipeline defined | ☐ | |
| Solution transport process | ☐ | |

---

## Authentication & Identity Checklist

### Microsoft Entra ID

| Checkpoint | Status | Notes |
|------------|--------|-------|
| Entra ID configured and accessible | ☐ | |
| Organization information verified | ☐ | |
| User synchronization working | ☐ | |
| SSO configured | ☐ | |
| Conditional Access policies (if needed) | ☐ | |
| Third-party IdP federation (if applicable) | ☐ | |

### External System Authentication

| System | Auth Method | Configuration Complete | Tested |
|--------|-------------|----------------------|--------|
| SAP SuccessFactors | ☐ OAuth 2.0 ☐ Entra ID ☐ Basic | ☐ | ☐ |
| Workday | ☐ OAuth 2.0 ☐ Basic ☐ Certificate | ☐ | ☐ |
| ServiceNow | ☐ OAuth 2.0 ☐ OIDC ☐ Certificate ☐ Basic | ☐ | ☐ |

---

## External Systems Integration Checklist

### SAP SuccessFactors (if applicable)

| Checkpoint | Status | Notes |
|------------|--------|-------|
| Solution package installed | ☐ | |
| OData v2.0 endpoint configured | ☐ | |
| OAuth 2.0 authentication working | ☐ | |
| Entra ID app registration | ☐ | |
| Employee read scenario templates | ☐ | |
| Employee write scenario templates | ☐ | |
| Manager read scenario templates | ☐ | |
| Manager write scenario templates | ☐ | |
| Environment variables configured | ☐ | |
| Connection reference active | ☐ | |
| Power Automate flows enabled | ☐ | |
| Test employee profile read | ☐ | |
| Test employee profile update | ☐ | |

### Workday (if applicable)

| Checkpoint | Status | Notes |
|------------|--------|-------|
| Solution package installed | ☐ | |
| RaaS endpoint accessible | ☐ | |
| Authentication configured | ☐ | |
| Tenant URL configured | ☐ | |
| Custom report templates configured | ☐ | |
| Scenario configurations defined | ☐ | |
| User Context field mappings | ☐ | |
| Column support configuration | ☐ | |
| Filter support configuration | ☐ | |
| Environment variables configured | ☐ | |
| Connection reference active | ☐ | |
| Power Automate flows enabled | ☐ | |
| Test employee data retrieval | ☐ | |
| Test time-off request | ☐ | |

### ServiceNow (if applicable)

| Checkpoint | Status | Notes |
|------------|--------|-------|
| Solution package installed | ☐ | |
| Instance URL configured | ☐ | |
| Knowledge connector configured | ☐ | |
| M365 Copilot Connector installed (SN) | ☐ | |
| Authentication configured | ☐ | |
| HRSD/ITSM starter configuration | ☐ | |
| Advanced Scripts configured (if needed) | ☐ | |
| Live Agent integration (if needed) | ☐ | |
| Knowledge indexing limits verified (< 200 pages) | ☐ | |
| Hierarchical permissions configured | ☐ | |
| Environment variables configured | ☐ | |
| Connection reference active | ☐ | |
| Power Automate flows enabled | ☐ | |
| Test HR case creation | ☐ | |
| Test ticket status retrieval | ☐ | |

---

## Content & Knowledge Sources Checklist

### SharePoint Configuration

| Checkpoint | Status | Notes |
|------------|--------|-------|
| SharePoint sites/libraries identified | ☐ | |
| Knowledge sources added to agent | ☐ | |
| Semantic indexing limits validated (< 200 pages) | ☐ | |
| SharePoint metadata configured | ☐ | |
| Managed properties mapped | ☐ | |
| RefinableString properties configured | ☐ | |
| Advanced filtering (KQL) configured | ☐ | |
| User Context variables for filtering | ☐ | |
| Content reindexed after changes | ☐ | |
| Heading structure optimized (H1-H6) | ☐ | |
| Document permissions validated (RLS) | ☐ | |
| Knowledge source naming convention | ☐ | |
| Knowledge instructions defined | ☐ | |

### Content Quality

| Item | Verified | Notes |
|------|----------|-------|
| Proper heading hierarchy used | ☐ | |
| Metadata populated | ☐ | |
| No broken links | ☐ | |
| Content up-to-date | ☐ | |
| Regional/localized content separated | ☐ | |

---

## Topics Configuration Checklist

### Required Topics

| Topic Name | Enabled | Configured | Tested | Notes |
|------------|---------|------------|--------|-------|
| [Admin] User Context - Setup | ☐ | ☐ | ☐ | |
| [System] Response Preparation | ☐ | ☐ | ☐ | |
| [System] On Error | ☐ | ☐ | ☐ | |
| [System] Log Telemetry Event | ☐ | ☐ | ☐ | |
| [System] Microsoft Self Help (IT only) | ☐ | ☐ | ☐ | |
| [Example] Crafted Response | ☐ | ☐ | ☐ | |
| [Example] Sensitive Topics | ☐ | ☐ | ☐ | |
| Seek Emotional Intelligence Response | ☐ | ☐ | ☐ | |
| Seek Clarification (Ambiguity) | ☐ | ☐ | ☐ | |
| Agent handoff topics (if needed) | ☐ | ☐ | ☐ | |

### Custom Topics

| Topic Name | Purpose | Trigger Phrases | Tested |
|------------|---------|-----------------|--------|
| 1. | | | ☐ |
| 2. | | | ☐ |
| 3. | | | ☐ |
| 4. | | | ☐ |
| 5. | | | ☐ |

---

## Agent Configuration Checklist

### Branding & Appearance

| Item | Configured | Notes |
|------|-----------|-------|
| Agent name customized | ☐ | |
| Agent logo uploaded | ☐ | |
| Short description (tagline) | ☐ | |
| Long description | ☐ | |
| Agent color theme | ☐ | |

### Instructions & Personality

| Item | Completed | Notes |
|------|-----------|-------|
| Global agent instructions written | ☐ | |
| Agent personality defined (3-5 attributes) | ☐ | |
| Tone and voice guidelines | ☐ | |
| Boundaries and fallback defined | ☐ | |
| Non-standard terms/acronyms defined | ☐ | |
| Response structure guidelines | ☐ | |
| Markdown formatting used | ☐ | |

### Variables & Configuration

| Item | Status | Notes |
|------|--------|-------|
| User Context variables created | ☐ | |
| Global variables defined | ☐ | |
| Tool names referenced explicitly | ☐ | |
| Environment variables configured | ☐ | |
| Connection references configured | ☐ | |
| Actions/Plugins configured | ☐ | |

### Starter Prompts

| Category | Prompts Configured | Count | Notes |
|----------|-------------------|-------|-------|
| HR Policies | ☐ | /4 | |
| Benefits & Leave | ☐ | /4 | |
| IT Support | ☐ | /4 | |
| (Max 12 total) | ☐ | /12 | |

---

## Testing & Quality Assurance Checklist

### Golden Prompts Testing

| Category | Prompts Created | Tested | Pass Rate | Notes |
|----------|----------------|--------|-----------|-------|
| Core functionality | ☐ ( /10) | ☐ | _____% | |
| Integration points | ☐ ( /10) | ☐ | _____% | |
| Edge cases | ☐ ( /10) | ☐ | _____% | |
| Performance | ☐ ( /5) | ☐ | _____% | |
| Security | ☐ ( /10) | ☐ | _____% | |
| Sensitive topics | ☐ ( /5) | ☐ | _____% | |
| **TOTAL** | ☐ (50+ prompts) | ☐ | _____% | **Target: 100%** |

### Quality Benchmarks

| Quality Metric | Score (1-5) | Target | Status |
|----------------|-------------|--------|--------|
| Accuracy | _____ | 5 | ☐ |
| Completeness | _____ | 4+ | ☐ |
| Relevance | _____ | 4+ | ☐ |
| Usefulness | _____ | 4+ | ☐ |
| Exceptional | _____ | 3+ | ☐ |
| **Average** | _____ | **15+ (Good), 20+ (Great)** | ☐ |

### Test Scenarios

| Scenario | Tested | Result | Notes |
|----------|--------|--------|-------|
| Different prompt formats (keywords, phrases, questions) | ☐ | ☐ Pass ☐ Fail | |
| Multiple departments/regions | ☐ | ☐ Pass ☐ Fail | |
| Ambiguous queries | ☐ | ☐ Pass ☐ Fail | |
| Emotional/sensitive topics | ☐ | ☐ Pass ☐ Fail | |
| Unclear inputs | ☐ | ☐ Pass ☐ Fail | |
| System errors | ☐ | ☐ Pass ☐ Fail | |
| Unavailable data | ☐ | ☐ Pass ☐ Fail | |
| Citation validation | ☐ | ☐ Pass ☐ Fail | |

---

## Publishing & Deployment Checklist

### Solution Management

| Item | Status | Notes |
|------|--------|-------|
| Solution exported as managed | ☐ | |
| Solution imported to Test environment | ☐ | |
| Test environment validated | ☐ | |
| UAT testing completed | ☐ | |
| UAT sign-off obtained | ☐ | |
| Production environment prepared | ☐ | |
| Solution imported to Production | ☐ | |
| Production validation completed | ☐ | |

### Publishing Process

| Step | Status | Date | Notes |
|------|--------|------|-------|
| Agent published from Copilot Studio | ☐ | | |
| Microsoft 365 admin approval requested | ☐ | | |
| Microsoft 365 admin approval obtained | ☐ | | |
| Teams channel configured | ☐ | | |
| M365 Copilot channel configured | ☐ | | |
| Channel descriptions customized | ☐ | | |
| Pilot users group defined | ☐ | | |
| Agent enabled for pilot users | ☐ | | |
| Publishing delay expected (up to 48 hours) | ☐ | | |

### Go-Live Verification

| Verification | Status | Notes |
|--------------|--------|-------|
| Agent appears in M365 Copilot for pilot users | ☐ | |
| Agent appears in Teams for pilot users | ☐ | |
| Pilot users can interact with agent | ☐ | |
| External systems integrations working | ☐ | |
| Knowledge sources returning correct results | ☐ | |
| Topics triggering correctly | ☐ | |
| Error handling working properly | ☐ | |

### Post-Deployment

| Item | Status | Notes |
|------|--------|-------|
| Pilot feedback collection process active | ☐ | |
| Monitoring dashboards accessible | ☐ | |
| Error logging verified | ☐ | |
| Telemetry flowing to App Insights | ☐ | |
| Support process documented | ☐ | |
| Rollback plan documented | ☐ | |
| Phased rollout plan defined | ☐ | |

---

## Infrastructure & Security Checklist

### Network Configuration

| Item | Status | Notes |
|------|--------|-------|
| Power Platform outbound IPs allowlisted | ☐ | |
| SAP endpoint accessible from Power Platform | ☐ | |
| Workday endpoint accessible from Power Platform | ☐ | |
| ServiceNow endpoint accessible from Power Platform | ☐ | |
| Firewall rules documented | ☐ | |

### Security & Compliance

| Item | Status | Notes |
|------|--------|-------|
| Network security review completed | ☐ | |
| InfoSec approval obtained | ☐ | |
| DLP policies enforced | ☐ | |
| Data residency requirements met | ☐ | |
| GDPR compliance validated | ☐ | |
| HIPAA compliance (if applicable) | ☐ | |
| Certificate management process | ☐ | |
| Secrets management (Key Vault) | ☐ | |
| Audit logging enabled | ☐ | |

### Monitoring

| Item | Status | Notes |
|------|--------|-------|
| Microsoft Purview configured | ☐ | |
| Azure Application Insights configured | ☐ | |
| SIEM integration configured (if needed) | ☐ | |
| Copilot Analytics accessible | ☐ | |
| Usage dashboards configured | ☐ | |
| Billing/metering reports accessible | ☐ | |

---

## Known Limitations Awareness Checklist

| Limitation | Understood | Mitigation Plan | Status |
|------------|-----------|-----------------|--------|
| Mobile support pending (2026) | ☐ | | ☐ |
| Publishing delay (up to 48 hours) | ☐ | | ☐ |
| Semantic indexing limit (~200 pages) | ☐ | | ☐ |
| External system integration complexity | ☐ | | ☐ |
| Teams channel limitations | ☐ | | ☐ |
| Content handling limits | ☐ | | ☐ |
| Licensing/billing considerations | ☐ | | ☐ |
| Platform dependencies | ☐ | | ☐ |

---

## Sign-off Sheet

### Stakeholder Approvals

| Stakeholder | Role | Approval | Signature | Date |
|-------------|------|----------|-----------|------|
| | Power Platform Administrator | ☐ | | |
| | Environment Maker/Owner | ☐ | | |
| | Information Security | ☐ | | |
| | External System Administrators | ☐ | | |
| | Change Control Board | ☐ | | |
| | HR Leadership (for HR agent) | ☐ | | |
| | IT Leadership (for IT agent) | ☐ | | |
| | Microsoft 365 Administrator | ☐ | | |

### Final Go/No-Go Decision

**Deployment Readiness Status:** ☐ GO ☐ NO GO

**Scheduled Deployment Date:** ________________

**Approved By:** ________________ **Title:** ________________

**Signature:** ________________ **Date:** ________________

**Blockers (if any):**

1. ________________________________________
2. ________________________________________
3. ________________________________________

**Action Items Before Go-Live:**

1. ________________________________________
2. ________________________________________
3. ________________________________________

---

## Quick Reference - Critical Pre-flight Checks

Before proceeding to production deployment, ensure these **CRITICAL** items are complete:

- [ ] **PRE-001**: Microsoft 365 Copilot licenses assigned
- [ ] **PRE-002**: Copilot Studio licenses for makers
- [ ] **ENV-001**: Power Platform environment exists
- [ ] **ENV-002**: Dataverse database enabled
- [ ] **AUTH-001**: Microsoft Entra ID configured
- [ ] **TOPIC-001**: [Admin] User Context - Setup configured
- [ ] **TOPIC-002**: [System] Response Preparation enabled
- [ ] **CONFIG-007**: Agent global instructions written
- [ ] **CONFIG-012**: User Context variables created
- [ ] **QA-001**: Golden prompts library created (50+)
- [ ] **QA-002**: Core functionality prompts tested (100% pass rate)
- [ ] **QA-012**: Accuracy validation passed
- [ ] **PUB-001**: Solution exported as managed
- [ ] **PUB-003**: UAT testing completed with sign-off
- [ ] **PUB-006**: Microsoft 365 admin approval obtained

**If any critical item fails, DO NOT proceed to production deployment.**

---

**Document Version:** 1.0.0  
**Last Updated:** $(Get-Date -Format "yyyy-MM-dd")  
**ESS Pre-flight Deployment Validator**  
**For comprehensive validation, use the PowerShell module: `Test-ESSDeploymentReadiness`**
