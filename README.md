# Benefit Verification Application

## Overview

A care benefit verification system that handles the care benefit verification request initiation to care benefit verification result processing. The solution is implemented using health cloud objects that are part of the core salesforce platform.

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
                       │  (Review Mgmt)   │    │  Callouts       │
                       └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │  REST API       │
                                               │  (Results)      │
                                               └─────────────────┘
```

## Business Requirements
- **Benefits Verification Request**: Create Benefits Verification Requests.
- **Automated Processing**: send benefit verification requests aysnchronously to provider API
- **Real-time Integration**: Connect with external Benefits provider APIs
- **Case Management**: Create cases for verifications requests to be review by Representatives
- **REST API**: Provide endpoint for receiving verification results
- **Audit Trail**: Maintain complete records of all verification attempts

## Assumptions:
- **Salesforce Health Cloud**: Leverage Salesforce Core Health Cloud objects
- **Member Plans**: Select the first member plan available.
- **Medication Request**: Select the first Medication request available.
- **Practitioner**: Practitioner & patient relationship is already defined.

## Quick Start

### Demo Video
- https://www.loom.com/share/d7b8292b517641d885ca9b204d70ad31?sid=fd9d7310-ce57-4a61-a0ab-c39436c83690

### Installation Steps
1. Deploy the package to your Salesforce org
2. Assign the permission set to users
3. Configure named credentials
4. Set up assignment rules and queues
5. Configure external client app for API access

For detailed installation instructions, see [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md).

## Key Components

### Service Classes

#### `BenefitsVerificationService`
- **Purpose**: Service for benefit verification request workflow

#### `CareBenefitVerificationResultsAPI`
- **Purpose**: REST API endpoint for receiving verification results from the benefits provider.

## Running Tests

```bash
# Deploy and run all tests
sf project deploy start -d force-app/main/default/classes/ -l RunLocalTests

# Run specific test classes
sf apex run test --class-names BenefitsVerificationServiceTest
sf apex run test --class-names CareBenefitVerificationResultsAPITest
```

### Test Coverage

The project includes test coverage for:
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
###
- **Package Installation Link**: Version0.1.0-3
 -https://login.salesforce.com/packaging/installPackage.apexp?p0=04ta5000009yDoPAAU
  
#### 3. Salesforce Developer Edition Org For Namespace

### Trail org sign up page links
- https://help.salesforce.com/s/articleView?id=ind.hc_trial_org.htm&type=5

## Current Implementation Status

### ✅ Completed Features
- Core benefit verification service
- REST API endpoint for results
- test coverage
- Postman collection for testing
- 2GP packaging configuration
- Error handling

### Issues
1. **Unable to create stable package**
   - API Limit for sf package version create command - Developer Edition org.
   - Package is not ready to be installed.


## Additional Resources

- **API Documentation**: See [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for complete API documentation
- **Postman Collection**: Included for testing the RESTful API
- **Installation Guide**: See [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) for detailed setup instructions 

 
