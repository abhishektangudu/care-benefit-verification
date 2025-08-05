# Benefit Verification Application - Installation Guide

## Overview

This guide provides step-by-step instructions for installing and configuring the Benefit Verification Application in your Salesforce Health Cloud org. The application requires specific setup of assignment rules and queues to function properly.

## Prerequisites

### System Requirements
- **Salesforce Edition**: Health Cloud or Enterprise Edition with Health Cloud licenses

## Installation Steps

### Step 1: Deploy the Package

#### Option A: Using Salesforce CLI
```bash
# Install the package
sf package install --package "BenefitVerification@0.1.0-3" --target-org YourOrgAlias --wait 20 --security-type AllUsers

# Deploy unpackaged components
sf project deploy start --source-dir unpackaged --target-org YourOrgAlias
```

#### Option B: Using Salesforce Setup
1. Navigate to **Setup** → **Packages** → **Installed Packages**
2. Click **Install a Package**
3. Enter the package name: `BenefitVerification`
4. Select **Install for All Users**
5. Click **Install**

### Step 2: Assign Permission Sets

1. Navigate to **Setup** → **Users** → **Permission Sets**
2. Find **Benefit Verification API Permissions**
3. Click **Manage Assignments**
4. Add users who need access to the benefit verification functionality

## Post-Install Configuration

### Step 1: Create Assignment Rules

The application uses assignment rules to route cases to appropriate queues. You need to create assignment rules for the Case object.

#### 1.1 Navigate to Assignment Rules
1. Go to **Setup** → **Support** → **Cases** → **Assignment Rules**
2. Click **New** to create a new assignment rule

#### 1.2 Create "Benefits Verification" Assignment Rule

**Rule Details:**
- **Rule Name**: `Benefits Verification`
- **Active**: Checked
- **Description**: Routes benefit verification cases to appropriate queues

**Rule Entries:**

**Entry 1 - Drug Benefit Requests:**
- **Order**: 1
- **Assigned To**: `Drug_Benefit_Request` (Queue)
- **Assigned To Type**: Queue
- **Criteria**: 
  - **Field**: `Case.RecordTypeId`
  - **Operator**: equals
  - **Value**: `PreAuthorization` (Record Type ID)

**Entry 2 - Service Benefit Verification:**
- **Order**: 2
- **Assigned To**: `Service_Benefit_Verification_Request` (Queue)
- **Assigned To Type**: Queue
- **Criteria**:
  - **Field**: `Case.RecordTypeId`
  - **Operator**: equals
  - **Value**: `ServiceRequest` (Record Type ID)

### Step 2: Create Required Queues

#### 2.1 Create "Drug_Benefit_Request" Queue

1. Navigate to **Setup** → **Support** → **Cases** → **Queues**
2. Click **New**
3. Configure the queue:
   - **Queue Name**: `Drug_Benefit_Request`
   - **Queue Email**: `drug-benefit-requests@yourcompany.com`
   - **Supported Objects**: Case
   - **Queue Members**: Add appropriate users or groups

#### 2.2 Create "Service_Benefit_Verification_Request" Queue

1. Navigate to **Setup** → **Support** → **Cases** → **Queues**
2. Click **New**
3. Configure the queue:
   - **Queue Name**: `Service_Benefit_Verification_Request`
   - **Queue Email**: `service-benefit-requests@yourcompany.com`
   - **Supported Objects**: Case
   - **Queue Members**: Add appropriate users or groups

### Step 3: Verify Record Types

Ensure the following Case record types exist in your org:

#### 3.1 PreAuthorization Record Type
- **Developer Name**: `PreAuthorization`
- **Label**: `PreAuthorization`
- **Business Process**: PreAuthorization

#### 3.2 ServiceRequest Record Type
- **Developer Name**: `ServiceRequest`
- **Label**: `Service Request`
- **Business Process**: Care Requests

### Step 4: Configure External Client App

#### 4.1 Create Integration User
1. Navigate to **Setup** → **Users** → **Users**
2. Click **New User**
3. Configure the integration user:
   - **First Name**: `Benefit`
   - **Last Name**: `Verification`
   - **Email**: `benefit.verification@yourcompany.com`
   - **Username**: `benefit.verification@yourcompany.com`
   - **Profile**: `System Administrator` (or create a custom profile with minimal permissions)
   - **User License**: `Salesforce`
   - **Active**: Checked
4. Save the user and note the User ID

#### 4.2 Configure External Client App
1. Navigate to **Setup** → **App Manager** → **New Connected App**
2. Configure the connected app:
   - **Connected App Name**: `Benefit_Verification_Connected_App`
   - **API Name**: `Benefit_Verification_Connected_App`
   - **Contact Email**: Your email address
   - **Enable OAuth Settings**: Checked
   - **Callback URL**: `https://login.salesforce.com/services/oauth2/callback`
   - **Selected OAuth Scopes**: 
     - Access and manage your data (api)
     - Perform requests at any time (refresh_token, offline_access)
3. Save the connected app
4. Note the **Consumer Key** and **Consumer Secret** for API authentication

#### 4.3 Assign Integration User to Connected App
1. In the connected app detail page, click **Manage**
2. Click **Edit Policies**
3. Set **Permitted Users** to `Admin approved users are pre-authorized`
4. Save the changes
5. Click **Manage Profiles**
6. Add the integration user profile to the connected app
7. Save the changes
 