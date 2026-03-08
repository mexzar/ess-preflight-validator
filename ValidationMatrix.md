# ESS Pre-flight Deployment Validation Matrix

## Validation Categories and Checkpoints

### 1. Prerequisites Validation (Critical Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| PRE-001 | Microsoft 365 Copilot licenses assigned to users | Critical | PowerShell Graph API | License count > 0 | prerequisites#licensing |
| PRE-002 | Copilot Studio licenses for admins/makers | Critical | PowerShell Graph API | Required licenses present | prerequisites#licensing |
| PRE-003 | Microsoft Teams access for users | Critical | PowerShell Graph API | Teams licenses verified | prerequisites#licensing |
| PRE-004 | Copilot Studio capacity configured | Critical | Power Platform API | Capacity allocated | prerequisites#set-up-copilot-studio-capacity |
| PRE-005 | Pay-As-You-Go (PayG) configured if needed | High | Power Platform API | PayG setup or prepaid messages | prerequisites#configure-pay-as-you-go |
| PRE-006 | Prepaid message capacity purchased | High | Power Platform API | Message capacity > 0 | prerequisites#set-up-prepaid-messages |
| PRE-007 | Capacity planning documented | Medium | Manual review | Planning doc exists | prerequisites#capacity-planning |
| PRE-008 | Global Admin role assigned | Critical | Entra ID API | Role assignment verified | prerequisites#required-roles |
| PRE-009 | Power Platform Admin role assigned | Critical | Power Platform API | Role assignment verified | prerequisites#required-roles |
| PRE-010 | Environment Maker role assigned | Critical | Power Platform API | Role assignment verified | prerequisites#required-roles |
| PRE-011 | External system administrators identified | High | Manual review | Contacts documented | prerequisites#required-roles |
| PRE-012 | InfoSec team engaged | High | Manual review | InfoSec approval obtained | prerequisites#required-roles |
| PRE-013 | Change control board approval | High | Manual review | CCB approval documented | prerequisites#required-roles |

### 2. Environment Configuration (Critical Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| ENV-001 | Power Platform environment created | Critical | Power Platform API | Environment exists | prepare#set-up-your-power-platform-environment |
| ENV-002 | Dataverse database enabled | Critical | Power Platform API | Dataverse = Yes | prepare#set-up-your-power-platform-environment |
| ENV-003 | Environment type is Managed | High | Power Platform API | Managed environment | prepare#set-up-your-power-platform-environment |
| ENV-004 | Release cycle set to Standard | Medium | Power Platform API | Standard release | prepare#preparation-checklist |
| ENV-005 | Copilot Studio accessible in environment | Critical | Copilot Studio API | Access confirmed | prepare#preparation-checklist |
| ENV-006 | Preferred solution created | High | Dataverse API | Unmanaged solution exists | install#set-up-a-preferred-solution |
| ENV-007 | Solution publisher configured | High | Dataverse API | Publisher with prefix | install#set-up-a-preferred-solution |
| ENV-008 | DLP policies reviewed | High | Power Platform API | DLP policies documented | prepare#allow-the-external-systems-connector |
| ENV-009 | Required connectors allowlisted | High | Power Platform API | Connectors in DLP | prepare#allow-the-external-systems-connector |
| ENV-010 | ALM environments defined (Dev/Test/Prod) | High | Manual review | ALM strategy documented | deploy-overview-alm#determine-your-alm |
| ENV-011 | Source control configured | Medium | Manual review | Source control linked | deploy-overview-alm#determine-your-alm |

### 3. Authentication & Identity (Critical Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| AUTH-001 | Microsoft Entra ID configured | Critical | Graph API | Entra ID active | prerequisites#identity-authentication-sso |
| AUTH-002 | SSO configured in Entra | High | Entra API | SSO settings verified | prerequisites#identity-authentication-sso |
| AUTH-003 | Third-party IdP federation (if applicable) | High | Entra API | Federation configured | prerequisites#identity-authentication-sso |
| AUTH-004 | User identity sync validated | High | Graph API | Users synchronized | prerequisites#identity-authentication-sso |
| AUTH-005 | OAuth 2.0 endpoints configured | High | Custom connector | OAuth settings verified | External system docs |
| AUTH-006 | OIDC configuration validated | High | Custom connector | OIDC flow working | External system docs |
| AUTH-007 | Certificate-based auth (if used) | High | Certificate API | Certificates valid | External system docs |
| AUTH-008 | Basic auth secured (if used) | Medium | Security review | Credentials stored securely | External system docs |

### 4. External Systems - SAP SuccessFactors (High Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| SAP-001 | SAP SuccessFactors solution package installed | High | Dataverse API | Package components present | sap-successfactors |
| SAP-002 | OData v2.0 endpoint accessible | High | HTTP connector test | Endpoint responds | sap-successfactors |
| SAP-003 | OAuth 2.0 authentication configured | High | Connector test | Auth token obtained | sap-successfactors |
| SAP-004 | Entra ID integration configured | High | Entra API | App registration exists | sap-successfactors |
| SAP-005 | Employee read scenario templates | High | Config validation | Templates valid JSON | sap-employee-read-write-scenarios |
| SAP-006 | Employee write scenario templates | High | Config validation | Templates valid JSON | sap-employee-read-write-scenarios |
| SAP-007 | Manager read scenario templates | High | Config validation | Templates valid JSON | sap-manager-read-write-scenarios |
| SAP-008 | Manager write scenario templates | High | Config validation | Templates valid JSON | sap-manager-read-write-scenarios |
| SAP-009 | Filter expressions validated | Medium | JSON schema | Filter syntax correct | sap-employee-read-write-scenarios |
| SAP-010 | Request entities configured | Medium | Config validation | Entities mapped | sap-employee-read-write-scenarios |
| SAP-011 | Permissions metadata defined | High | Config validation | Role permissions set | sap-employee-read-write-scenarios |
| SAP-012 | Environment variables set | High | Power Platform API | Variables configured | sap-successfactors |
| SAP-013 | Connection reference configured | High | Dataverse API | Connection active | sap-successfactors |
| SAP-014 | Power Automate flows imported | High | Flow API | Flows exist and enabled | sap-successfactors |
| SAP-015 | Test employee profile read | Critical | Flow execution | Data retrieved | sap-employee-read-write-scenarios |
| SAP-016 | Test employee profile update | Critical | Flow execution | Update successful | sap-employee-read-write-scenarios |

### 5. External Systems - Workday (High Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| WD-001 | Workday solution package installed | High | Dataverse API | Package components present | workday |
| WD-002 | Workday RaaS endpoint accessible | High | HTTP connector test | Endpoint responds | workday#technical-synopsis |
| WD-003 | SOAP/RaaS authentication configured | High | Connector test | Auth successful | workday#prerequisites |
| WD-004 | Basic auth credentials secured | High | Security review | Credentials in Key Vault | workday#prerequisites |
| WD-005 | OAuth 2.0 configured (if used) | Medium | Connector test | OAuth flow working | workday#prerequisites |
| WD-006 | Workday tenant URL configured | High | Config validation | URL format valid | workday#prerequisites |
| WD-007 | Custom report templates configured | High | XML validation | Templates valid XML | workday-report-template-config |
| WD-008 | Scenario configurations defined | High | Config validation | Scenarios mapped | workday#topics |
| WD-009 | API request templates validated | Medium | XML schema | Templates well-formed | workday-report-template-config |
| WD-010 | Response properties mapped | Medium | Config validation | Property mappings correct | workday-report-template-config |
| WD-011 | User Context field mappings | High | Config validation | Fields mapped to globals | workday#workday-user-context |
| WD-012 | Column support configuration | Medium | Config validation | Columns defined | workday-columns-support-config |
| WD-013 | Sort support configuration | Medium | Config validation | Sort options defined | workday-sort-support-config |
| WD-014 | Filter support configuration | Medium | Config validation | Filters configured | workday-filter-support-config |
| WD-015 | Sub-filter support configuration | Low | Config validation | Sub-filters defined | workday-sub-filter-support-config |
| WD-016 | Prompts support configuration | Medium | Config validation | Prompts configured | workday-prompts-support-config |
| WD-017 | Output support configuration | Medium | Config validation | Output format defined | workday-output-support-config |
| WD-018 | Share support configuration | Low | Config validation | Sharing options set | workday-share-support-config |
| WD-019 | Advanced configuration settings | Low | Config validation | Advanced options set | workday-advanced-support-config |
| WD-020 | Environment variables configured | High | Power Platform API | Variables set | workday#prerequisites |
| WD-021 | Connection reference configured | High | Dataverse API | Connection active | workday#prerequisites |
| WD-022 | Power Automate flows imported | High | Flow API | Flows exist and enabled | workday#topics |
| WD-023 | Test employee data retrieval | Critical | Flow execution | Data retrieved | workday#topics |
| WD-024 | Test time-off request | Critical | Flow execution | Request processed | workday#topics |

### 6. External Systems - ServiceNow (High Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| SN-001 | ServiceNow solution package installed | High | Dataverse API | Package components present | servicenow |
| SN-002 | ServiceNow instance URL configured | High | Config validation | URL accessible | servicenow#prerequisites |
| SN-003 | Knowledge connector configured | High | Connector test | Connector active | servicenow#servicenow-knowledge-connector |
| SN-004 | M365 Copilot Connector installed (SN) | High | ServiceNow API | Connector installed | servicenow#servicenow-knowledge-connector |
| SN-005 | OAuth/OIDC authentication configured | High | Connector test | Auth flow working | servicenow-hrsd-itsm#authentication-methods |
| SN-006 | Certificate-based auth (if used) | High | Certificate API | Certificates valid | servicenow-hrsd-itsm#authentication-methods |
| SN-007 | Basic auth configured (if used) | Medium | Security review | Credentials secured | servicenow-hrsd-itsm#authentication-methods |
| SN-008 | Entra ID OIDC integration | High | Entra API | App registration exists | servicenow-hrsd-itsm#authentication-methods |
| SN-009 | HRSD/ITSM starter configuration | High | JSON validation | Config valid JSON | servicenow-hrsd-itsm#starter-configurations |
| SN-010 | FilterCriteria configured | Medium | Config validation | Filters defined | servicenow-hrsd-itsm#starter-configurations |
| SN-011 | SortCriteria configured | Medium | Config validation | Sort options set | servicenow-hrsd-itsm#starter-configurations |
| SN-012 | OutputFieldMapping configured | High | Config validation | Fields mapped | servicenow-hrsd-itsm#starter-configurations |
| SN-013 | UserParameters configured | Medium | Config validation | Parameters defined | servicenow-hrsd-itsm#starter-configurations |
| SN-014 | Advanced Scripts configured | Medium | Script validation | Scripts valid | servicenow#advanced-scripts |
| SN-015 | Live Agent integration (if used) | Medium | Connector test | Handoff working | servicenow-live-agent |
| SN-016 | ESS Copilot Summary table created | Medium | ServiceNow API | Table exists | servicenow-live-agent#custom-table |
| SN-017 | Virtual topic flow configured | Medium | Flow validation | Flow logic correct | servicenow-live-agent#virtual-topic |
| SN-018 | Knowledge indexing limits verified | High | ServiceNow API | < 200 pages indexed | servicenow#limitations |
| SN-019 | Hierarchical permissions configured | High | ServiceNow API | Permissions scripted | servicenow#hierarchical-permissions |
| SN-020 | Environment variables configured | High | Power Platform API | Variables set | servicenow-hrsd-itsm |
| SN-021 | Connection reference configured | High | Dataverse API | Connection active | servicenow-hrsd-itsm |
| SN-022 | Power Automate flows imported | High | Flow API | Flows exist and enabled | servicenow-hrsd-itsm#topics |
| SN-023 | Test HR case creation | Critical | Flow execution | Case created | servicenow-hrsd-itsm#topics |
| SN-024 | Test ticket status retrieval | Critical | Flow execution | Status retrieved | servicenow-hrsd-itsm#topics |

### 7. Content & Knowledge Sources (High Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| CONT-001 | SharePoint knowledge sources identified | High | Manual review | Sources documented | customize#configure-knowledge-sources |
| CONT-002 | SharePoint sites/libraries configured | High | SharePoint API | Permissions verified | customize#configure-sharepoint-knowledge-source |
| CONT-003 | Knowledge sources added to agent | Critical | Copilot Studio API | Sources active | customize#configure-sharepoint-knowledge-source |
| CONT-004 | Semantic indexing limits validated | High | Content count | < 200 pages per source | known-issues-limitations |
| CONT-005 | SharePoint metadata configured | High | SharePoint API | Site columns populated | sharepoint-filtering#prerequisites |
| CONT-006 | Managed properties mapped | High | Search schema | Properties queryable | sharepoint-filtering#prerequisites |
| CONT-007 | RefinableString properties configured | Medium | Search schema | Refinable/searchable | sharepoint-filtering#prerequisites |
| CONT-008 | Advanced filtering (KQL) configured | Medium | Knowledge config | KQL syntax valid | sharepoint-filtering#add-kql-filters |
| CONT-009 | User Context variables for filtering | Medium | Variable validation | Variables referenced | sharepoint-filtering#capture-user-context |
| CONT-010 | Content reindexed after changes | Medium | SharePoint API | Reindex completed | sharepoint-filtering#prerequisites |
| CONT-011 | Heading structure optimized | Medium | Content review | H1-H6 hierarchy | known-issues-limitations |
| CONT-012 | Document permissions validated | High | SharePoint API | RLS configured | customize#configure-knowledge-sources |
| CONT-013 | No attachment indexing verified | Low | Config review | Expectation set | servicenow#limitations |
| CONT-014 | Knowledge source naming convention | Medium | Config review | Names explicit | design-best-practices#name-tools-explicitly |
| CONT-015 | Knowledge instructions defined | Medium | Config review | Instructions clear | design-best-practices#knowledge-and-data |

### 8. Topics Configuration (High Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| TOPIC-001 | [Admin] User Context - Setup configured | Critical | Topic validation | Redirects set | customize#admin-user-context-setup |
| TOPIC-002 | [System] Response Preparation enabled | Critical | Topic validation | Disclaimer/badge config | customize#system-response-preparation |
| TOPIC-003 | [Example] Crafted Response configured | Medium | Topic validation | Trigger phrases set | customize#example-crafted-response |
| TOPIC-004 | [Example] Sensitive Topics configured | High | Topic validation | Triggers validated | customize#example-sensitive-topics |
| TOPIC-005 | [System] On Error customized | High | Topic validation | Error messages set | customize#system-on-error |
| TOPIC-006 | [System] Log Telemetry Event configured | Medium | Topic validation | App Insights linked | customize#system-log-telemetry-event |
| TOPIC-007 | [System] Microsoft Self Help (IT only) | Medium | Topic validation | Enable/disable decision | customize#system-microsoft-self-help |
| TOPIC-008 | Agent handoff topics configured | Medium | Topic validation | Handoff URLs set | customize#agent-handoff-scenario-name |
| TOPIC-009 | Emotional Intelligence topic configured | High | Topic validation | EQ responses set | emotional-quotient-ambiguity#how-it-works |
| TOPIC-010 | Ambiguity clarification configured | High | Topic validation | Clarification logic set | emotional-quotient-ambiguity#how-ambiguity-works |
| TOPIC-011 | Custom topics for org needs | Medium | Topic validation | 3-5 custom topics | deployment-checklist#step-5-customize-topics |
| TOPIC-012 | Topic trigger phrases tested | High | Test panel | Triggers work | customize#customize-topics |
| TOPIC-013 | Topic nodes logic validated | High | Flow review | Logic correct | customize#customize-topics |
| TOPIC-014 | Official Answer badge working | Medium | Production test | Badge visible in M365 | customize#system-response-preparation |
| TOPIC-015 | Disclaimer messages customized | Medium | Config review | Org-specific messages | customize#system-response-preparation |

### 9. Agent Configuration & Customization (High Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| CONFIG-001 | Agent name customized | Medium | Config review | Org-specific name | customize#customize-the-look-and-content |
| CONFIG-002 | Agent logo uploaded | Medium | Config review | Logo meets specs | customize#customizing-logo |
| CONFIG-003 | Agent short description set | Medium | Config review | Description clear | customize#customize-the-look-and-content |
| CONFIG-004 | Agent long description set | Medium | Config review | Description complete | customize#customize-the-look-and-content |
| CONFIG-005 | Starter prompts configured (up to 12) | High | Config review | Prompts relevant | customize#customize-starter-prompts |
| CONFIG-006 | Starter prompt categories defined | Medium | Config review | Categories logical | customize#customize-starter-prompts |
| CONFIG-007 | Agent global instructions written | Critical | Config review | Instructions comprehensive | design-best-practices#about-writing-instructions |
| CONFIG-008 | Agent personality defined | High | Config review | 3-5 key attributes | design-best-practices#developing-agent-personality |
| CONFIG-009 | Tone and voice guidelines | High | Config review | Tone appropriate | design-best-practices#developing-agent-personality |
| CONFIG-010 | Boundaries and fallback defined | High | Config review | Boundaries clear | design-best-practices#define-boundaries-fallback |
| CONFIG-011 | Non-standard terms/acronyms defined | Medium | Config review | Glossary included | design-best-practices#define-non-standard-words |
| CONFIG-012 | User Context variables created | Critical | Variable validation | Variables global | design-best-practices#add-user-context-variables |
| CONFIG-013 | Tool names referenced explicitly | Medium | Config review | Exact names used | design-best-practices#name-tools-explicitly |
| CONFIG-014 | Response structure guidelines | Medium | Config review | Format instructions | design-best-practices#write-instructions-structure |
| CONFIG-015 | Markdown used in instructions | Medium | Config review | Formatting applied | design-best-practices#write-instructions-structure |
| CONFIG-016 | Environment variables configured | High | Power Platform API | All vars set | customize#understanding-components |
| CONFIG-017 | Connection references configured | High | Dataverse API | All connections active | customize#understanding-components |
| CONFIG-018 | Actions/Plugins configured | Medium | Copilot Studio API | Actions enabled | customize#actions |

### 10. Testing & Quality Assurance (Critical Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| QA-001 | Golden prompts library created | Critical | Test plan review | 50+ prompts curated | deploy-overview-alm#golden-prompt-testing |
| QA-002 | Core functionality prompts | Critical | Test execution | All prompts pass | deploy-overview-alm#golden-prompt-testing |
| QA-003 | Integration point prompts | High | Test execution | Integrations work | deploy-overview-alm#golden-prompt-testing |
| QA-004 | Edge case prompts | High | Test execution | Graceful handling | deploy-overview-alm#golden-prompt-testing |
| QA-005 | Performance prompts | Medium | Test execution | Response time OK | deploy-overview-alm#golden-prompt-testing |
| QA-006 | Security prompts | High | Test execution | Auth/perms work | deploy-overview-alm#golden-prompt-testing |
| QA-007 | Test in Copilot Studio test pane | Critical | Manual testing | Responses accurate | customize#customization-checklist |
| QA-008 | Test with different prompt formats | High | Manual testing | All formats work | design-best-practices#tips-for-benchmark-testing |
| QA-009 | Test across scenarios and roles | High | Manual testing | Context-aware | design-best-practices#tips-for-benchmark-testing |
| QA-010 | Test edge cases | Critical | Manual testing | Graceful failures | design-best-practices#tips-for-benchmark-testing |
| QA-011 | Response quality scoring (1-5) | High | Quality review | Avg score > 15 | design-best-practices#how-to-approach-benchmarks |
| QA-012 | Accuracy validation | Critical | Quality review | Responses correct | design-best-practices#create-a-test-plan |
| QA-013 | Completeness validation | High | Quality review | Nothing missing | design-best-practices#create-a-test-plan |
| QA-014 | Relevance validation | High | Quality review | Fits user intent | design-best-practices#create-a-test-plan |
| QA-015 | Usefulness validation | High | Quality review | Helps user act | design-best-practices#create-a-test-plan |
| QA-016 | Citation validation | Medium | Quality review | Citations maintained | design-best-practices#fix-issues-with-citations |
| QA-017 | Sensitive topics tested | Critical | Security review | Appropriate responses | emotional-quotient-ambiguity |
| QA-018 | Ambiguous queries tested | High | UX testing | Clarification requested | emotional-quotient-ambiguity |
| QA-019 | Emotional intelligence tested | High | UX testing | Empathetic responses | emotional-quotient-ambiguity |

### 11. Publishing & Deployment (Critical Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| PUB-001 | Solution exported as managed | Critical | ALM process | Export successful | deploy-overview-alm |
| PUB-002 | Test environment deployment | Critical | ALM process | Import successful | deploy-overview-alm |
| PUB-003 | UAT testing completed | Critical | Test execution | UAT sign-off | deploy-overview-alm#quality-assurance-strategy |
| PUB-004 | Production environment prepared | Critical | Environment check | Prod env ready | deploy-overview-alm |
| PUB-005 | Agent published from Copilot Studio | Critical | Publishing API | Publish successful | deployment-checklist#step-8-test-and-publish |
| PUB-006 | Microsoft 365 admin approval | Critical | Admin center | Approval obtained | publish |
| PUB-007 | Teams channel configured | High | Teams admin | Channel active | publish |
| PUB-008 | M365 Copilot channel configured | High | M365 admin | Channel active | publish |
| PUB-009 | Agent enabled for pilot users | High | Admin center | Pilot group assigned | deployment-checklist#step-8-test-and-publish |
| PUB-010 | Channel description customized | Medium | Channel config | Description set | design-best-practices#instructions-define-voice |
| PUB-011 | Publishing delay expected (48 hrs) | Medium | Timeline planning | Timeline adjusted | known-issues-limitations |
| PUB-012 | Agent appears in M365 Copilot | Critical | End-user test | Agent visible | publish |
| PUB-013 | Agent appears in Teams | Critical | End-user test | Agent visible | publish |
| PUB-014 | Pilot feedback collection process | High | Process defined | Feedback mechanism | deployment-checklist#step-8-test-and-publish |
| PUB-015 | Rollback plan documented | High | Documentation | Plan exists | deploy-overview-alm |

### 12. Infrastructure & Security (Critical Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| INFRA-001 | IP allowlisting completed | Critical | Network config | IPs allowlisted | prepare#infrastructure-setup |
| INFRA-002 | Power Platform outbound IPs allowed | Critical | Firewall rules | Rules configured | prepare#infrastructure-setup |
| INFRA-003 | External system endpoints accessible | Critical | Network test | Connectivity verified | prepare#infrastructure-setup |
| INFRA-004 | Firewall rules documented | High | Documentation | Rules documented | prepare#infrastructure-setup |
| INFRA-005 | Network security review completed | High | Security review | Approval obtained | prerequisites#required-roles |
| INFRA-006 | DLP policies configured | Critical | Power Platform | Policies enforced | prepare#allow-the-external-systems-connector |
| INFRA-007 | Data residency requirements met | High | Compliance review | Residency verified | prerequisites |
| INFRA-008 | GDPR compliance validated | High | Legal review | Compliance confirmed | overview#implementation-considerations |
| INFRA-009 | HIPAA compliance (if applicable) | High | Legal review | Compliance confirmed | overview#implementation-considerations |
| INFRA-010 | Certificate management process | High | Process review | Process documented | External system docs |
| INFRA-011 | Secrets management configured | Critical | Key Vault | Secrets secured | External system docs |
| INFRA-012 | Audit logging enabled | High | Monitoring config | Logging active | usage-analytics |
| INFRA-013 | Microsoft Purview configured | Medium | Purview API | Auditing enabled | usage-analytics |
| INFRA-014 | Azure App Insights configured | Medium | App Insights API | Telemetry flowing | usage-analytics |
| INFRA-015 | SIEM integration configured | Medium | SIEM config | Events forwarded | usage-analytics |

### 13. Monitoring & Analytics (Medium Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| MON-001 | Copilot Analytics configured | Medium | Viva Insights | Analytics visible | usage-analytics |
| MON-002 | Usage dashboards accessible | Medium | Admin center | Dashboards available | usage-analytics |
| MON-003 | Conversation tracking enabled | Medium | Copilot Studio | Tracking active | usage-analytics |
| MON-004 | Error logging configured | High | App Insights | Errors logged | customize#system-log-telemetry-event |
| MON-005 | Performance monitoring active | Medium | App Insights | Metrics collected | usage-analytics |
| MON-006 | User feedback collection enabled | High | Copilot Studio | Feedback captured | deployment-checklist#step-8-test-and-publish |
| MON-007 | Conversation ID tracking | Medium | Telemetry | IDs logged | customize#system-on-error |
| MON-008 | Billing/metering reports | High | Admin center | Reports accessible | prerequisites#capacity-planning |

### 14. Known Limitations Awareness (Medium Priority)

| Checkpoint ID | Validation Item | Priority | Validation Method | Expected Result | Documentation |
|---------------|----------------|----------|-------------------|-----------------|---------------|
| LIMIT-001 | Mobile support timeline understood | Medium | Documentation review | 2026 timeline known | known-issues-limitations |
| LIMIT-002 | Publishing delay awareness (48 hrs) | High | Documentation review | Delay expected | known-issues-limitations |
| LIMIT-003 | Semantic indexing limit (200 pages) | High | Documentation review | Limit understood | known-issues-limitations |
| LIMIT-004 | External system complexity awareness | High | Documentation review | Complexity understood | known-issues-limitations |
| LIMIT-005 | Teams channel limitations known | Medium | Documentation review | Limitations documented | known-issues-limitations |
| LIMIT-006 | Content handling limits understood | Medium | Documentation review | Limits known | known-issues-limitations |
| LIMIT-007 | Licensing/billing awareness | High | Documentation review | Costs estimated | known-issues-limitations |
| LIMIT-008 | Platform dependency awareness | Medium | Documentation review | Dependencies known | known-issues-limitations |

### 12. SkillsSpec — Workday Report Structure (High Priority)

| Checkpoint ID | Validation Item | Priority | Stage | Validation Method | Expected Result | Gating |
|---------------|----------------|----------|-------|-------------------|-----------------|--------|
| WD-RPT-001 | RaaS endpoint accessible | Critical | Detection | HTTP GET customreport2 | HTTP 200 | Yes |
| WD-RPT-002 | Report returns data | Critical | Detection | XML response parse | Non-empty result set | Yes |
| WD-RPT-003 | Required columns present (13) | Critical | Detection | XML column inspection | All 13 columns found | Yes |
| WD-RPT-004 | Calculated fields present (3) | High | Detection | XML calc field check | Country_Code, Level, Mgr_Sup_Org_Id | Yes |
| WD-RPT-005 | Report response time | Medium | Detection | Latency measurement | < 5 seconds | Advisory |

### 13. SkillsSpec — Workday Connection Sharing (High Priority)

| Checkpoint ID | Validation Item | Priority | Stage | Validation Method | Expected Result | Gating |
|---------------|----------------|----------|-------|-------------------|-----------------|--------|
| WD-SHARE-001 | Workday SOAP connections shared | High | Detection | PP Admin API | All shared with tenant | Yes |
| WD-SHARE-002 | Workday OAuth connections shared | High | Detection | PP Admin API | All shared with tenant | Yes |
| WD-SHARE-003 | Dataverse connections shared | High | Detection | PP Admin API | Shared with tenant | Yes |
| WD-SHARE-004 | Overall sharing assessment | High | Diagnosis | Aggregate check | All connections tenant-shared | Yes |

### 14. SkillsSpec — Entra SSO for Workday (High Priority)

| Checkpoint ID | Validation Item | Priority | Stage | Validation Method | Expected Result | Gating |
|---------------|----------------|----------|-------|-------------------|-----------------|--------|
| WD-ENTRA-001 | Workday Enterprise App exists | High | Detection | Graph API / Manual | Service Principal found | Yes |
| WD-ENTRA-002 | SSO mode set to SAML | High | Detection | Graph API / Manual | PreferredSingleSignOnMode = saml | Yes |
| WD-ENTRA-003 | SAML Relay State configured | Medium | Detection | Graph API / Manual | Relay State non-empty | Advisory |
| WD-ENTRA-004 | App ID URI configured | High | Detection | Graph API / Manual | identifierUris non-empty | Yes |

### 15. SkillsSpec — ServiceNow End-to-End (Critical Priority)

| Checkpoint ID | Validation Item | Priority | Stage | Validation Method | Expected Result | Gating |
|---------------|----------------|----------|-------|-------------------|-----------------|--------|
| SN-E2E-001 | HRSD Knowledge Base accessible | Critical | Detection | REST /kb_knowledge | HTTP 200 + results | Yes |
| SN-E2E-002 | HR Case table accessible | Critical | Detection | REST /sn_hr_core_case | HTTP 200 | Yes |
| SN-E2E-003 | ITSM Incidents accessible | High | Detection | REST /incident | HTTP 200 | Yes |
| SN-E2E-004 | User lookup functional | High | Detection | REST /sys_user | HTTP 200 + user found | Yes |

### 16. SkillsSpec — ServiceNow OAuth/OIDC Config (High Priority)

| Checkpoint ID | Validation Item | Priority | Stage | Validation Method | Expected Result | Gating |
|---------------|----------------|----------|-------|-------------------|-----------------|--------|
| SN-OAUTH-001 | OIDC Provider record exists | High | Diagnosis | REST /oauth_entity | Record found | Yes |
| SN-OAUTH-002 | Entra metadata URL correct | High | Diagnosis | REST field validation | login.microsoftonline.com | Yes |
| SN-OAUTH-003 | Redirect URL matches GCS | High | Diagnosis | REST field validation | gcs.office.com endpoint | Yes |
| SN-OAUTH-004 | Token lifespan — refresh | High | Diagnosis | REST field validation | ≥ 31536000 | Yes |
| SN-OAUTH-005 | Token lifespan — access | Medium | Diagnosis | REST field validation | ≥ 43200 | Advisory |
| SN-OAUTH-006 | User claim & JTI config | High | Diagnosis | REST field validation | Claim=Oid, JTI=false | Yes |

### 17. SkillsSpec — Entra SSO for ServiceNow (High Priority)

| Checkpoint ID | Validation Item | Priority | Stage | Validation Method | Expected Result | Gating |
|---------------|----------------|----------|-------|-------------------|-----------------|--------|
| SN-ENTRA-001 | ServiceNow App Registration exists | High | Detection | Graph API / Manual | App Registration found | Yes |
| SN-ENTRA-002 | Token claims configured | High | Detection | Graph API / Manual | aud, email, UPN claims | Yes |
| SN-ENTRA-003 | Exposed API scope configured | High | Detection | Graph API / Manual | user_impersonation scope | Yes |
| SN-ENTRA-004 | Pre-authorized client configured | High | Detection | Graph API / Manual | Client c26b24aa authorized | Yes |

### 18. SkillsSpec — ServiceNow Connection Sharing (High Priority)

| Checkpoint ID | Validation Item | Priority | Stage | Validation Method | Expected Result | Gating |
|---------------|----------------|----------|-------|-------------------|-----------------|--------|
| SN-SHARE-001 | ServiceNow connections shared | High | Detection | PP Admin API | Shared with tenant | Yes |

### 19. SkillsSpec — Topic End-to-End (High Priority)

| Checkpoint ID | Validation Item | Priority | Stage | Validation Method | Expected Result | Gating |
|---------------|----------------|----------|-------|-------------------|-----------------|--------|
| TOPIC-E2E-001 | Workday topic end-to-end | Critical | Detection | Copilot prompt test | Valid response | Yes |
| TOPIC-E2E-002 | ServiceNow topic end-to-end | High | Detection | Copilot prompt test | Valid response | Yes |
| TOPIC-E2E-003 | Response quality assessment | Medium | Diagnosis | Keyword + latency | < 5s, relevant content | Advisory |

## Validation Priority Levels

- **Critical**: Must pass before proceeding to deployment
- **High**: Should pass; requires remediation plan if fails
- **Medium**: Important but can be addressed post-deployment
- **Low**: Nice-to-have; optional configuration

## Validation Methods

- **PowerShell Graph API**: Use Microsoft Graph PowerShell SDK
- **Power Platform API**: Use Power Platform admin PowerShell cmdlets
- **Copilot Studio API**: Use Copilot Studio management APIs
- **Dataverse API**: Query Dataverse tables directly
- **HTTP Connector Test**: Execute test HTTP requests
- **Manual Review**: Human verification with documentation
- **Config Validation**: JSON/XML/YAML schema validation
- **Test Execution**: Run functional tests
- **Security Review**: InfoSec team verification

## Remediation Guidance

Each failed validation checkpoint should include:
1. **Root Cause Analysis**: Why the validation failed
2. **Impact Assessment**: What functionality is affected
3. **Step-by-Step Remediation**: How to fix the issue
4. **Verification Steps**: How to confirm the fix
5. **Documentation Links**: Relevant Microsoft Learn articles
6. **Estimated Time**: Time required for remediation

## Reporting

Validation results should be reported in:
- **Executive Summary**: High-level pass/fail by category
- **Detailed Findings**: All checkpoints with status
- **Critical Issues**: Priority-ordered list of blockers
- **Remediation Plan**: Timed action items
- **Sign-off Sheet**: Stakeholder approvals
