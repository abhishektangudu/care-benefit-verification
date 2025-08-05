# Care Benefit Verification Results API

## Overview

The Care Benefit Verification Results API provides a RESTful endpoint to receive benefit verification results from external systems and create CoverageBenefit records linked to CareBenefitVerifyRequest records.

## Endpoint

**URL:** `/services/apexrest/care-benefit-verification-results`  
**Method:** POST  
**Content-Type:** `application/json`

## Authentication

The API requires Salesforce authentication. Use one of the following methods:

1. **OAuth 2.0**: Include Bearer token in Authorization header
2. **Session ID**: Include session ID in Authorization header
3. **Username/Password**: Use basic authentication

## Request Format

### JSON Structure

```json
{
  "benefitsRequestId": "a0x000000000000",
  "memberNumber": "123456789",
  "groupNumber": "GRP001",
  "isCoverageActive": true,
  "benefitPeriodStartDate": "2024/01/01",
  "benefitPeriodEndDate": "2024/12/31",
  "errorResponse": "",
  "jsonResponse": "{\"status\":\"success\"}",
  "benefitNotes": "Standard health benefits coverage",
  "coinsuranceNotes": "20% coinsurance after deductible",
  "copayNotes": "Standard copay structure",
  "deductibleNotes": "Annual deductible applies",
  "disclaimer": "Benefits subject to change",
  "lifetimeMaximumNotes": "No lifetime maximum",
  "outofPocketNotes": "Out-of-pocket maximum applies",
  "emergencyDepartmentCopay": 150.00,
  "pharmaCopayAmount": 10.00,
  "primaryCareCopay": 25.00,
  "specialistCopay": 40.00,
  "urgentCareCopay": 50.00,
  "inNetworkCoinsuranceAmount": 0.00,
  "inNetworkCoinsurancePercentage": 20.0,
  "inNetworkLifetimeMaximum": 0.00,
  "outofNetworkCoinsuranceAmount": 0.00,
  "outofNetworkCoinsurancePercentage": 40.0,
  "outofNetworkLifetimeMaximum": 0.00,
  "individualInNetworkDeductibleApplied": 0.00,
  "individualInNetworkDeductibleLimit": 1500.00,
  "individualInNetworkDeductibleRemaining": 1500.00,
  "individualInNetworkOutofPocketApplied": 0.00,
  "individualInNetworkOutofPocketLimit": 3000.00,
  "individualInNetworkOutofPocketRemaining": 3000.00,
  "individualOutofNetworkDeductibleApplied": 0.00,
  "individualOutofNetworkDeductibleLimit": 3000.00,
  "individualOutofNetworkDeductibleRemain": 3000.00,
  "individualOutofNetworkOutofPocketApplied": 0.00,
  "individualOutofNetworkOutofPocketLimit": 6000.00,
  "individualOutofNetworkOutofPocketRemain": 6000.00,
  "familyInNetworkDeductibleApplied": 0.00,
  "familyInNetworkDeductibleLimit": 3000.00,
  "familyInNetworkDeductibleRemaining": 3000.00,
  "familyInNetworkOutofPocketApplied": 0.00,
  "familyInNetworkOutofPocketLimit": 6000.00,
  "familyInNetworkOutofPocketRemaining": 6000.00,
  "familyOutofNetworkDeductibleApplied": 0.00,
  "familyOutofNetworkDeductibleLimit": 6000.00,
  "familyOutofNetworkDeductibleRemaining": 6000.00,
  "familyOutofNetworkOutofPocketApplied": 0.00,
  "familyOutofNetworkOutofPocketLimit": 12000.00,
  "familyOutofNetworkOutofPocketRemaining": 12000.00,
  "benefitsItem": [
    {
      "serviceType": "Health Benefits Plan Coverage",
      "serviceTypeCode": "30",
      "benefitsCategory": "Plan Coverage and General Benefits",
      "notes": "Standard health benefits coverage",
      "inPlanNetworkIndicator": true,
      "benefitsItemLimit": [
        {
          "benefitCode": "C",
          "benefitValue": "2800",
          "benefitMetricType": "Money",
          "coverageLevel": "Family",
          "limitNotes": "Annual deductible",
          "termType": "Calendar Year",
          "networkType": "IN"
        }
      ]
    }
  ]
}
```

### Required Fields

- `benefitsRequestId`: The ID of the CareBenefitVerifyRequest record in Salesforce

### Optional Fields

 Rest all are optional fields.

## Response Format

### Success Response

```json
{
  "success": true,
  "message": "Benefit verification result processed successfully",
  "coverageBenefitId": "a0x000000000000",
  "errors": []
}
```

### Error Response

```json
{
  "success": false,
  "message": "API Error: benefitsRequestId is required",
  "coverageBenefitId": null,
  "errors": ["benefitsRequestId is required"]
}
```

## Testing with Postman Collection

A comprehensive Postman collection is available for testing the API: **`Benefit Verification API.postman_collection.json`**

### Collection Overview

The Postman collection includes multiple test scenarios to validate different aspects of the API:

#### **1. Authentication**
- Implemented at the Collection Level to Generate Access Token using the refresh token.
- **Get Access Token**: Just in case if you want to debug the tOAuth 2.0 authentication setup for Salesforce API access

#### **2. Benefit Verification Results**

##### **Submit Success Response**
- **Purpose**: Test successful benefit verification with comprehensive data

##### **Submit Error Response**
- **Purpose**: Test error handling with invalid member data

##### **Submit Invalid Request**
- **Purpose**: Test validation for missing required fields(e.g. `benefitsRequestId` field)

#### **3. Data Validation**

##### **Test Invalid CareBenefitVerifyRequest ID**
- **Purpose**: Test handling of non-existent request IDs

### Environment Variables

The collection uses the following environment variables:

### Importing the Collection

1. **Download the collection**: `Benefit Verification API.postman_collection.json`
2. **Import into Postman**: File → Import → Select the JSON file
3. **Set up environment variables**: Create a new environment with the required variables
4. **Configure authentication**: Update the OAuth 2.0 settings with your Salesforce credentials

### Running Tests

#### **Quick Start**
1. Import the collection
2. Set up environment variables
3. Run "Get Access Token" to authenticate
4. Execute "Submit Success Response" to test the main functionality

#### **Comprehensive Testing**
1. **Authentication**: Ensure OAuth 2.0 is properly configured
2. **Success Scenarios**: Run "Submit Success Response" with valid data
3. **Error Scenarios**: Test "Submit Error Response" and "Submit Invalid Request"
4. **Validation**: Run "Test Invalid CareBenefitVerifyRequest ID"

## Error Handling

The API returns appropriate error messages for various scenarios:

- **Missing benefitsRequestId**: Returns error indicating required field
- **Invalid benefitsRequestId**: Returns error if CareBenefitVerifyRequest not found
- **Invalid JSON**: Returns error for malformed JSON
- **Database errors**: Returns error with details
- **Field validation errors**: Returns specific field validation errors

### Error Response Examples

```json
{
  "success": false,
  "message": "API Error: benefitsRequestId is required",
  "coverageBenefitId": null,
  "errors": ["benefitsRequestId is required"]
}
```

```json
{
  "success": false,
  "message": "API Error: CareBenefitVerifyRequest not found with ID: a0x000000000000",
  "coverageBenefitId": null,
  "errors": ["CareBenefitVerifyRequest not found with ID: a0x000000000000"]
}
```

## Rate Limits

- Maximum request size: 6MB
- Maximum response time: 120 seconds
- Concurrent requests: Subject to Salesforce org limits

## Testing

Use the provided test class `CareBenefitVerificationResultsAPITest` to verify functionality

## Security Considerations

- The API uses `with sharing` to respect Salesforce sharing rules
- Input validation is performed on all required fields
- Error messages are logged for debugging
- Database operations are wrapped in try-catch blocks
- JSON deserialization includes error handling

## Related Objects

- **CareBenefitVerifyRequest**: Original verification request
- **CoverageBenefit**: Main benefit record (Health Cloud standard)
- **CoverageBenefitItem**: Individual benefit items (Health Cloud standard)
- **CoverageBenefitItemLimit**: Benefit limits and details (Health Cloud standard)
- **MemberPlan**: Insurance plan information (Health Cloud standard)
- **Account**: Patient information (Person Account)

## Implementation Notes

- **Date Format**: All dates must be in `YYYY/MM/DD` format
- **Decimal Values**: All monetary amounts should be provided as decimal values
- **Boolean Values**: Use `true`/`false` for boolean fields
- **Field Validation**: Some fields may be temporarily disabled due to picklist validation
- **Error Logging**: All errors are logged with `System.debug(LoggingLevel.ERROR)` 