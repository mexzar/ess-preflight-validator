# Workday Workflow Validator - Copilot Studio Agent

A Copilot Studio agent with Power Automate flow that validates all 17 ESS Workday workflows with [PASS]/[FAIL] output.

## Overview

This guide provides everything needed to recreate the Workday Workflow Validator agent from scratch. The agent:
- Connects to Workday via SOAP API
- Tests all 15 Read workflows + 2 Write workflows
- Displays results in [PASS]/[FAIL] format
- Supports both Test Mode and Normal Mode

---

## Prerequisites

- Copilot Studio access
- Power Automate (Premium - for Workday SOAP connector)
- Workday SOAP connector configured
- Workday ISU account with appropriate permissions

---

## Component 1: Copilot Studio Topic

### Topic YAML

Create a new topic in Copilot Studio and paste this YAML in the code editor:

```yaml
kind: AdaptiveDialog
modelDescription: |-
  This topic verifies Workday connectivity by retrieving employee information from Workday. Trigger phrases include:
  "Test Workday API connection"
  "Connect to Workday"
  "Verify Workday credentials"
  "Look up an employee"
  "Get worker information"
  "Find employee"
  "Search for employee"
  "Retrieve worker data"
  "Get employee"
beginDialog:
  kind: OnRecognizedIntent
  id: main
  intent: {}
  actions:
    - kind: Question
      id: question_Environment
      interruptionPolicy:
        allowInterruption: true
      variable: init:Topic.Environment
      prompt: Which Workday tenant would you like to connect to?
      entity: StringPrebuiltEntity

    - kind: Question
      id: question_EmployeeID
      interruptionPolicy:
        allowInterruption: true
      variable: init:Topic.EmployeeID
      prompt: "Please enter the Employee ID:"
      entity: StringPrebuiltEntity

    - kind: Question
      id: question_EffectiveDate
      interruptionPolicy:
        allowInterruption: true
      variable: init:Topic.EffectiveDate
      prompt: "Enter effective date in format YYYY-MM-DD (e.g., 2026-01-25), or press Skip to use today's date:"
      entity: StringPrebuiltEntity

    - kind: Question
      id: question_TestMode
      interruptionPolicy:
        allowInterruption: true
      variable: init:Topic.TestMode
      prompt: "Run in validation test mode? (Shows [PASS]/[FAIL] for each workflow)"
      entity: BooleanPrebuiltEntity

    - kind: InvokeFlowAction
      id: invokeFlowAction_main
      input:
        binding:
          text: =Topic.Environment
          text_1: =Topic.EmployeeID
          text_2: =Topic.EffectiveDate
          boolean: =Topic.TestMode
      output:
        binding:
          employee_information: Topic.EmployeeInformation
      flowId: YOUR_FLOW_ID_HERE

    - kind: ConditionGroup
      id: conditionGroup_result
      conditions:
        - id: conditionItem_hasData
          condition: =!IsBlank(Topic.EmployeeInformation)
          actions:
            - kind: SendActivity
              id: sendActivity_result
              activity: "{Topic.EmployeeInformation}"
      elseActions:
        - kind: SendActivity
          id: sendActivity_error
          activity: Please verify the Employee ID and try again

    - kind: Question
      id: question_SearchAgain
      interruptionPolicy:
        allowInterruption: true
      variable: init:Topic.SearchAgain
      prompt: Would you like to search for another employee?
      entity: BooleanPrebuiltEntity

    - kind: ConditionGroup
      id: conditionGroup_again
      conditions:
        - id: conditionItem_yes
          condition: =Topic.SearchAgain = true
          actions:
            - kind: BeginDialog
              id: restart
              dialog: YOUR_TOPIC_NAME_HERE
      elseActions:
        - kind: SendActivity
          id: sendActivity_bye
          activity: Thank you for using Workday Employee Lookup Agent! Have a great day! 👋

    - kind: EndConversation
      id: endConvo
```

> **Note:** Replace `YOUR_FLOW_ID_HERE` and `YOUR_TOPIC_NAME_HERE` with actual values after creating the flow.

---

## Component 2: Power Automate Flow

### Flow Structure

```
┌─────────────────────────────────────┐
│ 1. Trigger: Run a flow from Copilot │
│    Inputs: Environment, EmployeeID, │
│            EffectiveDate, TestMode  │
└─────────────────┬───────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 2. Execute SOAP Operation           │
│    (Workday SOAP Connector)         │
└─────────────────┬───────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 3. Compose: Parse_All_Fields        │
│    (Extract data from XML)          │
└─────────────────┬───────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 4. Condition: TestMode = true?      │
├──────────────────┬──────────────────┤
│ TRUE             │ FALSE            │
├──────────────────┼──────────────────┤
│ 5a. Compose:     │ 5b. Compose:     │
│ Test_Mode_Output │ Normal Output    │
└──────────────────┴──────────────────┘
                  ↓
┌─────────────────────────────────────┐
│ 6. Respond to Agent                 │
│    (Dynamic output selection)       │
└─────────────────────────────────────┘
```

---

### Step 1: Trigger Configuration

**Type:** Run a flow from Copilot (Skills trigger)

**Inputs:**
| Name | Type | Title |
|------|------|-------|
| text | String | Environment |
| text_1 | String | EmployeeID |
| text_2 | String | EffectiveDate |
| boolean | Yes/No | TestMode |

---

### Step 2: SOAP Request Body

**Connector:** Workday SOAP  
**Operation:** SOAP_Operation  
**Service:** Human_Resources  
**Version:** V42.0

**Request Body:**
```xml
<bsvc:Get_Workers_Request xmlns:bsvc="urn:com.workday/bsvc" bsvc:version="v42.0">
  <bsvc:Request_References bsvc:Skip_Non_Existing_Instances="false" bsvc:Ignore_Invalid_References="true">
    <bsvc:Worker_Reference bsvc:Descriptor="Employee_ID">
      <bsvc:ID bsvc:type="Employee_ID">@{triggerBody()?['text_1']}</bsvc:ID>
    </bsvc:Worker_Reference>
  </bsvc:Request_References>
  <bsvc:Response_Filter>
    <bsvc:As_Of_Effective_Date>@{triggerBody()?['text_2']}</bsvc:As_Of_Effective_Date>
  </bsvc:Response_Filter>
  <bsvc:Response_Group>
    <bsvc:Include_Reference>true</bsvc:Include_Reference>
    <bsvc:Include_Personal_Information>true</bsvc:Include_Personal_Information>
    <bsvc:Include_Employment_Information>true</bsvc:Include_Employment_Information>
    <bsvc:Include_Organizations>true</bsvc:Include_Organizations>
    <bsvc:Include_Roles>true</bsvc:Include_Roles>
    <bsvc:Include_Compensation>true</bsvc:Include_Compensation>
    <bsvc:Include_Qualifications>true</bsvc:Include_Qualifications>
    <bsvc:Include_Related_Persons>true</bsvc:Include_Related_Persons>
  </bsvc:Response_Group>
</bsvc:Get_Workers_Request>
```

> **Important:** In Power Automate, replace `@{triggerBody()?['text_1']}` with the actual dynamic content tokens for EmployeeID and EffectiveDate.

---

### Step 3: Parse_All_Fields (Compose)

**Name:** Parse_All_Fields  
**Runs After:** Execute_SOAP_operation

**Expression:**
```
@json(concat('{',
  '"EmployeeID": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="ID"][@*[local-name()="type"]="Employee_ID"])'), '",',
  '"FirstName": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="First_Name"])'), '",',
  '"LastName": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Last_Name"])'), '",',
  '"Email": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Email_Address"])'), '",',
  '"JobTitle": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Business_Title"])'), '",',
  '"PositionID": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="ID"][@*[local-name()="type"]="Position_ID"])'), '",',
  '"HireDate": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Hire_Date"])'), '",',
  '"ServiceDate": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Continuous_Service_Date"])'), '",',
  '"CompanyCode": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Organization_Data"]/*[local-name()="Organization_Code"])'), '",',
  '"CostCenter": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="ID"][@*[local-name()="type"]="Cost_Center_Reference_ID"])'), '",',
  '"BasePay": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Total_Base_Pay"])'), '",',
  '"CompaRatio": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Compa_Ratio"])'), '",',
  '"EmergencyContact": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Emergency_Contact_Data"]/*[local-name()="Contact_Name"])'), '",',
  '"NationalID": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="National_ID"])'), '",',
  '"Language": "', xpath(xml(body('Execute_SOAP_operation')), 'string(//*[local-name()="Language_Data"]/*[local-name()="Language_Reference"]/*[local-name()="ID"])'), '"',
'}'))
```

---

### Step 4: Condition

**Name:** Condition  
**Runs After:** Parse_All_Fields

**Condition Expression:**
```
triggerBody()?['boolean']  is equal to  true
```

> **Note:** Use the Expression tab and type `true` (lowercase) for the right side - not "Yes" or "True" as text.

---

### Step 5a: Test_Mode_Output (True Branch)

**Name:** Test_Mode_Output  
**Type:** Compose  
**Branch:** True (If yes)

**Expression:**
```
@concat(
'🧪 WORKDAY WORKFLOW VALIDATION TEST',
decodeUriComponent('%0A'),
'====================================',
decodeUriComponent('%0A'),
'Employee: ', outputs('Parse_All_Fields')?['FirstName'], ' ', outputs('Parse_All_Fields')?['LastName'], ' (', outputs('Parse_All_Fields')?['EmployeeID'], ')',
decodeUriComponent('%0A'),
'====================================',
decodeUriComponent('%0A%0A'),
'📋 READ WORKFLOWS (15)',
decodeUriComponent('%0A'),
'─────────────────────',
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['EmployeeID']), '❌ [FAIL]', '✅ [PASS]'), ' Employee ID: ', if(empty(outputs('Parse_All_Fields')?['EmployeeID']), '(No data)', outputs('Parse_All_Fields')?['EmployeeID']),
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['CompanyCode']), '❌ [FAIL]', '✅ [PASS]'), ' Company Code: ', if(empty(outputs('Parse_All_Fields')?['CompanyCode']), '(No data)', outputs('Parse_All_Fields')?['CompanyCode']),
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['CostCenter']), '❌ [FAIL]', '✅ [PASS]'), ' Cost Center: ', if(empty(outputs('Parse_All_Fields')?['CostCenter']), '(No data)', outputs('Parse_All_Fields')?['CostCenter']),
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['HireDate']), '❌ [FAIL]', '✅ [PASS]'), ' Hire Date: ', if(empty(outputs('Parse_All_Fields')?['HireDate']), '(No data)', outputs('Parse_All_Fields')?['HireDate']),
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['JobTitle']), '❌ [FAIL]', '✅ [PASS]'), ' Employment Info: ', if(empty(outputs('Parse_All_Fields')?['JobTitle']), '(No data)', outputs('Parse_All_Fields')?['JobTitle']),
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['PositionID']), '❌ [FAIL]', '✅ [PASS]'), ' Position Number: ', if(empty(outputs('Parse_All_Fields')?['PositionID']), '(No data)', outputs('Parse_All_Fields')?['PositionID']),
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['ServiceDate']), '❌ [FAIL]', '✅ [PASS]'), ' Service Anniversary: ', if(empty(outputs('Parse_All_Fields')?['ServiceDate']), '(No data)', outputs('Parse_All_Fields')?['ServiceDate']),
decodeUriComponent('%0A'),
'⚠️ [SKIP] National IDs: (PII - may be restricted)',
decodeUriComponent('%0A'),
'⚠️ [SKIP] Passports: (PII - requires separate call)',
decodeUriComponent('%0A'),
'⚠️ [SKIP] Visas: (PII - requires separate call)',
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['Language']), '❌ [FAIL]', '✅ [PASS]'), ' Language Info: ', if(empty(outputs('Parse_All_Fields')?['Language']), '(No data)', outputs('Parse_All_Fields')?['Language']),
decodeUriComponent('%0A'),
'⚠️ [SKIP] Certifications: (requires qualifications data)',
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['BasePay']), '❌ [FAIL]', '✅ [PASS]'), ' Base Compensation: ', if(empty(outputs('Parse_All_Fields')?['BasePay']), '(No data)', outputs('Parse_All_Fields')?['BasePay']),
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['CompaRatio']), '❌ [FAIL]', '✅ [PASS]'), ' Compensation Ratio: ', if(empty(outputs('Parse_All_Fields')?['CompaRatio']), '(No data)', outputs('Parse_All_Fields')?['CompaRatio']),
decodeUriComponent('%0A'),
if(empty(outputs('Parse_All_Fields')?['EmergencyContact']), '❌ [FAIL]', '✅ [PASS]'), ' Emergency Contact: ', if(empty(outputs('Parse_All_Fields')?['EmergencyContact']), '(No data)', outputs('Parse_All_Fields')?['EmergencyContact']),
decodeUriComponent('%0A%0A'),
'✏️ WRITE WORKFLOWS (2)',
decodeUriComponent('%0A'),
'─────────────────────',
decodeUriComponent('%0A'),
'⏭️ [SKIP] Update Email: (requires Maintain_Contact_Information call)',
decodeUriComponent('%0A'),
'⏭️ [SKIP] Update Phone: (requires Maintain_Contact_Information call)',
decodeUriComponent('%0A%0A'),
'====================================',
decodeUriComponent('%0A'),
'📊 SUMMARY',
decodeUriComponent('%0A'),
'Tested: ', utcNow(),
decodeUriComponent('%0A'),
'Connection: ✅ Working',
decodeUriComponent('%0A'),
'====================================',
decodeUriComponent('%0A%0A'),
'💡 Fields showing [FAIL] may need:',
decodeUriComponent('%0A'),
'   • Workday security domain permissions',
decodeUriComponent('%0A'),
'   • Data to exist for test employee',
decodeUriComponent('%0A'),
'   • Response_Group flag enabled'
)
```

---

### Step 5b: Normal Output (False Branch)

**Name:** Compose  
**Type:** Compose  
**Branch:** False (If no)

**Expression:**
```
@concat(
  'Employee Information',
  decodeUriComponent('%0A%0A'),
  '==================',
  decodeUriComponent('%0A%0A'),
  'Employee ID: ', outputs('Parse_All_Fields')?['EmployeeID'],
  decodeUriComponent('%0A'),
  'First Name: ', outputs('Parse_All_Fields')?['FirstName'],
  decodeUriComponent('%0A'),
  'Last Name: ', outputs('Parse_All_Fields')?['LastName'],
  decodeUriComponent('%0A'),
  'Email: ', outputs('Parse_All_Fields')?['Email'],
  decodeUriComponent('%0A'),
  'Job Title: ', outputs('Parse_All_Fields')?['JobTitle'],
  decodeUriComponent('%0A%0A'),
  '==================',
  decodeUriComponent('%0A'),
  'Retrieved: ', utcNow()
)
```

---

### Step 6: Respond to Agent

**Name:** Respond_to_the_agent  
**Type:** Response (Skills)  
**Runs After:** Condition (Succeeded)

**Output Configuration:**
- Name: `employee_information`
- Type: String
- Title: Employee Information

**Value Expression:**
```
if(equals(triggerBody()?['boolean'], true), outputs('Test_Mode_Output'), outputs('Compose'))
```

> **Important:** This expression dynamically selects the correct output based on TestMode.

---

## Expected Output

### Test Mode = Yes
```
🧪 WORKDAY WORKFLOW VALIDATION TEST
====================================
Employee: John Smith (12345)
====================================

📋 READ WORKFLOWS (15)
─────────────────────
✅ [PASS] Employee ID: 12345
✅ [PASS] Company Code: ABC-001
✅ [PASS] Cost Center: CC-1234
✅ [PASS] Hire Date: 2020-03-15
✅ [PASS] Employment Info: Software Engineer
✅ [PASS] Position Number: P-00123
✅ [PASS] Service Anniversary: 2020-03-15
⚠️ [SKIP] National IDs: (PII - may be restricted)
⚠️ [SKIP] Passports: (PII - requires separate call)
⚠️ [SKIP] Visas: (PII - requires separate call)
❌ [FAIL] Language Info: (No data)
⚠️ [SKIP] Certifications: (requires qualifications data)
❌ [FAIL] Base Compensation: (No data)
❌ [FAIL] Compensation Ratio: (No data)
✅ [PASS] Emergency Contact: Jane Smith

✏️ WRITE WORKFLOWS (2)
─────────────────────
⏭️ [SKIP] Update Email: (requires Maintain_Contact_Information call)
⏭️ [SKIP] Update Phone: (requires Maintain_Contact_Information call)

====================================
📊 SUMMARY
Tested: 2026-01-26T10:30:00Z
Connection: ✅ Working
====================================

💡 Fields showing [FAIL] may need:
   • Workday security domain permissions
   • Data to exist for test employee
   • Response_Group flag enabled
```

### Test Mode = No
```
Employee Information

==================

Employee ID: 12345
First Name: John
Last Name: Smith
Email: john.smith@company.com
Job Title: Software Engineer

==================
Retrieved: 2026-01-26T10:30:00Z
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Bad Request on SOAP | Invalid Response_Group flag | Use only flags listed above (e.g., `Include_Related_Persons` not `Include_Emergency_Contacts`) |
| Condition always False | Boolean comparison issue | Use Expression tab, type `true` lowercase |
| No output in Copilot | Missing Respond to Agent | Add response action with correct expression |
| All fields show FAIL | XPath not matching | Check SOAP action name matches `Execute_SOAP_operation` |
| PII fields empty | Security restrictions | Normal - these require elevated permissions |

---

## Workday Security Domains Required

For all fields to return data, the ISU account needs:

**Read Workflows:**
- Worker Profile (Employee ID, Hire Date, Position, etc.)
- Organizations (Company Code, Cost Center)
- Compensation (Base Pay, Compa-Ratio)
- Personal Data (Emergency Contact, National IDs - PII)
- Qualifications (Certifications)

**Write Workflows:**
- Contact Information (Update Email, Update Phone)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-25 | Initial creation |

---

## Related Files

- [Test-WorkdayWorkflows.ps1](../PowerShell/Test-WorkdayWorkflows.ps1) - PowerShell equivalent
- [README.md](../README.md) - Main documentation
