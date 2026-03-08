# GitHub Issue Templates

To create issues from the backlog, use these templates:

## Bug Report Template
```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
1. Run '...'
2. Select '...'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable (sanitize any tenant/user info).

**Environment:**
- Tool Version: [e.g. 1.7.0]
- PowerShell Version: [e.g. 7.4.0]
- OS: [e.g. Windows 11]

**Additional context**
Any other relevant information.
```

## Feature Request Template
```markdown
**Is your feature request related to a problem?**
A clear description of the problem.

**Describe the solution you'd like**
What you want to happen.

**Describe alternatives you've considered**
Other solutions or workarounds.

**Additional context**
Any other relevant information.
```

---

## Public Backlog (Sanitized)

These are the planned features - see GitHub Issues for tracking:

### P0 - Critical
| ID | Feature | Status |
|----|---------|--------|
| #1 | User Scope Limiting - Support large tenants | Open |
| #2 | Variable Completeness Checker | ✅ Done (v1.8.0 — Test-WorkdayEnvironmentVariables enhanced) |
| #3 | Graph Module Dependency Check | Open |
| #4 | Consistent Report Path Detection | Open |
| #5 | ISV Connector Firewall Verification | Open |
| #6 | Workday Custom Topics XML Validation | Open |

### P1 - High
| ID | Feature | Status |
|----|---------|--------|
| #7 | Hub Agent Federation Scan | Open |
| #8 | Connection Sharing Validation | ✅ Done (v1.8.0 — Test-WorkdayConnectionSharing + Test-ServiceNowConnectionSharing) |
| #9 | Config Backup/Export | Open |
| #10 | DLP Permission Requirements Review | Open |
| #11 | Unified Environment Picker | Open |

### P2 - Medium
| ID | Feature | Status |
|----|---------|--------|
| #12 | ServiceNow Staging Table Detection | Open |
| #13 | SuccessFactors Validation Suite | Open |
| #14 | Custom Topics Detection | Open |
| #15 | ServiceNow Requests Support | Open |

### SkillsSpec Items (New — v1.8.0)
| ID | Feature | Status |
|----|---------|--------|
| #16 | SkillsSpec 4-Stage Output Format (Detection/Diagnosis/Remediation/Prevention) | ✅ Done |
| #17 | Workday RaaS Report Structure Validation | ✅ Done |
| #18 | Entra SSO Validation — Workday | ✅ Done |
| #19 | Entra SSO Validation — ServiceNow | ✅ Done |
| #20 | ServiceNow End-to-End Functional Tests | ✅ Done |
| #21 | ServiceNow OAuth/OIDC Deep Diagnostics | ✅ Done |
| #22 | ESS Topic End-to-End Functional Tests | ✅ Done |
| #23 | Connector Readiness Orchestrator | ✅ Done |
| #24 | Performance & ALM Readiness Checks | Open (pending spec update) |
| #25 | Telemetry — Dataverse / Application Insights | Open (pending spec update) |

---

*See individual GitHub Issues for detailed requirements and acceptance criteria.*
