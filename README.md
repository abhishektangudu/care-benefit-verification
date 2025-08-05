# Benefit Verification Application

## Overview

This Salesforce Health Cloud project implements a care benefit verification system that handles the care benefit verification request initiation to care benefit verification result processing. The solution is implemented using health cloud objects that are part of the core salesforce platform.

## Repository Structure

```
care-benefit-verification/
├── force-app/main/default/
│   ├── classes/                    # Apex classes
│   ├── objects/                    # Custom objects
│   ├── flows/                      # Salesforce Flows
│   ├── permissionsets/             # Permission sets
│   └── externalClientApps/         # External Client apps
├── config/                         # Project configuration
├── scripts/                        # Utility scripts
├── API_DOCUMENTATION.md           # Complete API documentation
├── Benefit Verification API.postman_collection.json  # Postman collection
├── INSTALLATION_GUIDE.md          # Detailed installation instructions
└── README.md                      # This file
```

## Key Components

### 1. Service Classes

#### `BenefitsVerificationService`
- **Purpose**: Service for benefit verification request workflow

#### `CareBenefitVerificationResultsAPI`
- **Purpose**: REST API endpoint for receiving verification results from the benefits provider.

### 2. Mock and Testing Classes

#### `MockHttpResponseGenerator`
- **Purpose**: HTTP callout mock for testing

#### `BVMockDataGenerator`
- **Purpose**: Test data generation utility

## Configuration

### Named Credentials

Set up a Named Credential called `Benefit_Verification_API` with:
- **URL**: Your external API endpoint
- **Identity Type**: Named Principal
- **Authentication Protocol**: OAuth 2.0 or Username/Password
- **Generate Authorization Header**: Enabled

### Permission Sets

The system includes a permission set `Benefit_Verification_API_Permissions` that provides:
- Access to custom objects
- API permissions
- Field-level security settings
- Custom Lightning App

### External Client Apps

An external client app `Benefit_Verification_Connected_App` is configured for:
- External API authentication
- OAuth 2.0 integration
- Secure credential management
- Package-compatible configuration

### 3. Data Models

#### Health Cloud Data Model
- **CareBenefitVerifyRequest**: Main request record for benefit verification
- **CoverageBenefit**: Main benefit record (Health Cloud standard)
- **CoverageBenefitItem**: Individual benefit items (Health Cloud standard)
- **CoverageBenefitItemLimit**: Benefit limits and details (Health Cloud standard)
- **MemberPlan**: Insurance plan information (Health Cloud standard)
- **MedicationRequest**: Prescription information (Health Cloud standard)
- **HealthcareProvider**: Provider details (Health Cloud standard)
- **HealthcareProviderNpi**: NPI information (Health Cloud standard)
- **CodeSetBundle**: Code set management (Health Cloud standard)
- **CodeSet**: Individual code definitions (Health Cloud standard)

#### Standard Objects
- **Account**: Patient and Payer records
- **Contact**: Provider information
- **Case**: Error case management

## API Documentation

API documentation is available in `API_DOCUMENTATION.md` including:
- Authentication methods
- Complete request/response formats
- Error handling scenarios
- Postman collection for testing
- Usage examples

## Inbound Integration (RESTful API) Testing with Postman Collection

### Collection Features
- **Authentication**: OAuth 2.0 setup for Salesforce API access
- **Success Scenarios**: Complete benefit data testing
- **Error Scenarios**: Invalid data and validation testing
- **Data Validation**: Database validation testing

### Test Scenarios Available
1. **Submit Success Response**: Comprehensive benefit data testing
2. **Submit Error Response**: Error handling with invalid data
3. **Submit Invalid Request**: Validation testing for missing fields
4. **Test Invalid CareBenefitVerifyRequest ID**: Database validation testing

## Usage Examples

### Flow Integration

```apex
// Invocable method for Flow integration
List<Id> patientIds = new List<Id>{ '001000000000000' };
BenefitsVerificationService.verifyBenefits(patientIds);
```

### Queueable Processing

```apex
// Process benefit verification requests asynchronously
List<CareBenefitVerifyRequest> requests = [SELECT Id FROM CareBenefitVerifyRequest WHERE Status = 'Pending'];
System.enqueueJob(new BenefitsVerificationService.BenefitVerificationCalloutQueueable(requests));
```

## Testing

### Running Tests

```bash
# Deploy and run all tests
sf project deploy start -d force-app/main/default/classes/ -l RunLocalTests

# Run specific test classes
sf apex run test --class-names BenefitsVerificationServiceTest
sf apex run test --class-names CareBenefitVerificationResultsAPITest
```

### Test Coverage

The project includes comprehensive test coverage for:
- Service layer functionality
- API endpoints and error handling
- Queueable processing
- Mock data generation
- Error case creation

### Test Classes

- **BenefitsVerificationServiceTest**: Tests the main service functionality
- **CareBenefitVerificationResultsAPITest**: Tests the REST API endpoint
- **MockHttpResponseGenerator**: HTTP callout mock for testing

## Error Handling

### Validation Errors
- **Missing Practitioner**: Patient without PCP relationship
- **Inactive Plan**: Member plan not active
- **Invalid Data**: Malformed request data

### Error Recovery
- Failed requests are marked as 'Error' status
- Error cases are created for tracking and manual review
- No automatic retry mechanism currently implemented

## Security Considerations

- **Sharing Rules**: All classes use `with sharing` to respect Salesforce sharing rules
- **Named Credentials**: External API credentials are stored securely
- **Input Validation**: All inputs are validated before processing
- **Error Logging**: Sensitive data is not logged in error messages
- **Permission Sets**: Granular access control
- **CRUD/FLS**: Security checks implemented where needed

## Orgs in Context

#### 1. Salesforce Trail Health Cloud Learning org For Development

| Key              | Value                                                        |
|------------------|--------------------------------------------------------------|
| Alias            | healthCloudOrg                                               |
| Api Version      | 64.0                                                         |
| Client Id        | PlatformCLI                                                  |
| Connected Status | Connected                                                    |
| Id               | 00Dbn00000qJDJlEAO                                           |
| Instance Url     | https://infinitus.my.salesforce.com                          |
| Sfdx Auth Url    | force://PlatformCLI::5Aep861UEZSe.tVXq9iuPW55ENKbR1i7xQA4x7A |
| Username         | abhishektangudu-5aun@force.com                               |

#### 2. Salesforce Trail Health Cloud Base Org For Devhub

| Key              | Value                                                        |
|------------------|--------------------------------------------------------------|
| Alias            | bene-veri-devhub                                             |
| Api Version      | 64.0                                                         |
| Client Id        | PlatformCLI                                                  |
| Connected Status | Connected                                                    |
| Id               | 00Da500001Mq8YlEAJ                                           |
| Instance Url     | https://beneveri.my.salesforce.com                           |
| Sfdx Auth Url    | force://PlatformCLI::5Aep8612FOkUjfmSUz0UxnPG2DfVY7ZVE15D.ho |
| Username         | abhishektangudu-d5br@force.com                               |

#### 3. Salesforce Developer Edition Org For Namespace

### Trail org sign up page links
- https://help.salesforce.com/s/articleView?id=ind.hc_trial_org.htm&type=5

### 2nd Generation Packaging

- **Command to generate 2GP package**:
  ```bash
  sf package create --name "BenefitVerification" --package-type Managed --path force-app/main/default --target-dev-hub bene-veri-devhub
  ```

- **Command to Create Package Version**:
  ```bash
  sf package version create --package "BenefitVerification" --wait 20 --installation-key-bypass -f config/project-scratch-def.json --tag "4 Aug 2025"
  ```

- **Command to Create Scratch Org to test the package**:
  ```bash
  sf org create scratch --definition-file config/project-scratch-def.json --alias TestOrg --set-default --no-namespace --target-dev-hub bene-veri-devhub
  ```

- **Command to install the Package in scratch org**:
  ```bash
  sf package install --package "BenefitVerification@0.1.0-3" --target-org TestOrg1 --wait 20 --security-type AllUsers
  ```

## Current Implementation Status

### ✅ Completed Features
- Core benefit verification service
- REST API endpoint for results
- Comprehensive test coverage
- Postman collection for testing
- 2GP packaging configuration
- Error handling

### Issues
1. **Unable to create stable package**
   - API Limit for sf package version create command
   - ContactContactRelation object issue - unable to find the correct setting that needs to be added to the scratch-def.json file which is needed to create a stable version of package

## Quick Start

For detailed installation instructions, see [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md).

### Installation Steps
1. Deploy the package to your Salesforce org
2. Assign the permission set to users
3. Configure named credentials
4. Set up assignment rules and queues
5. Configure external client app for API access 
 