# Benefit Verification Application

## Overview

This Salesforce Health Cloud project implements a care benefit verification system that handles the care benefit verification request initiation to care benefit verification result processing. The solution is implemented using health cloud objects that are part of the core salesforce platform.

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flow Trigger  │───▶│  Service Layer   │───▶│  Queueable      │
│   (UI/Process)  │    │  (Apex Classes)  │    │  (Async)        │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │  Case Creation   │    │  External API   │
                       │  (Error Mgmt)    │    │  Callouts       │
                       └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │  REST API       │
                                               │  (Results)      │
                                               └─────────────────┘
```

## Business Requirements

### Core Requirements
- **Automated Processing**: Handle benefit verification requests without manual intervention
- **Real-time Integration**: Connect with external insurance provider APIs
- **Error Management**: Create cases for failed verifications with proper routing
- **Scalability**: Process high volumes of requests asynchronously
- **Audit Trail**: Maintain complete records of all verification attempts

### Technical Requirements
- **Salesforce Health Cloud**: Leverage existing Health Cloud objects
- **Asynchronous Processing**: Use Queueable for API callouts
- **REST API**: Provide endpoint for receiving verification results
- **Assignment Rules**: Automatically route cases based on record type
- **Security**: Implement proper sharing and field-level security

## Quick Start

For detailed installation instructions, see [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md).

### Installation Steps
1. Deploy the package to your Salesforce org
2. Assign the permission set to users
3. Configure named credentials
4. Set up assignment rules and queues
5. Configure external client app for API access

## Key Components

### Service Classes

#### `BenefitsVerificationService`
- **Purpose**: Service for benefit verification request workflow

#### `CareBenefitVerificationResultsAPI`
- **Purpose**: REST API endpoint for receiving verification results from the benefits provider.

### Data Models

#### Health Cloud Objects
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

## Deployment

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

### Development Orgs

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


## Additional Resources

- **API Documentation**: See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete API documentation
- **Postman Collection**: Included for testing the RESTful API
- **Installation Guide**: See [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) for detailed setup instructions 
 