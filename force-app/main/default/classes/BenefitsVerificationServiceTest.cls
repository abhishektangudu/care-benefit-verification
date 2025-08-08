/**
 * @description Test class for BenefitsVerificationService
 */
@isTest
private class BenefitsVerificationServiceTest {

    @TestVisible private static Id patientAccountId;
    @TestVisible private static Id providerContactId;
    @TestVisible private static Id memberPlanId;
    @TestVisible private static Id medicationRequestId;
    
    /**
     * @description Create test data setup
     */
    @testSetup
    static void makeData() {
        Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PreAuthorization').getRecordTypeId();
        
        // Create patient and payer accounts
        Account patient = new Account(
            FirstName = 'John',
            LastName = 'Patient',
            PersonBirthdate = Date.newInstance(1985, 5, 15),
            PersonGender = 'Male'
        );
        insert patient;
        patientAccountId = patient.Id;
        
        Account payer = new Account(Name = 'United Health');
        insert payer;

        // Create provider with NPI
        Contact provider = new Contact(FirstName = 'Dr. Emily', LastName = 'Carter');
        insert provider;
        providerContactId = provider.Id;
        
        HealthcareProvider healthcareProvider = new HealthcareProvider(
            PractitionerId = provider.Id,
            Name = 'Dr. Emily Carter'
        );
        insert healthcareProvider;
        
        HealthcareProviderNpi npi = new HealthcareProviderNpi(
            Name = 'NPI for Dr. Emily Carter',
            PractitionerId = provider.Id, 
            Npi = '1234567890',
            IsActive = true
        );
        insert npi;

        // Create member plan
        Account plan = new Account(Name = 'Gold PPO Plan');
        insert plan;
        
        MemberPlan memberPlan = new MemberPlan(
            Name = 'Test Member Plan',
            MemberId = patient.Id,
            MemberNumber = 'MEMBER123',
            GroupNumber = 'GROUP456',
            Status = 'Active'
        );
        insert memberPlan;
        memberPlanId = memberPlan.Id;

        // Create medication request
        CodeSetBundle testMedicationCodeBundle = new CodeSetBundle(
            Name = 'Test Medication Code Bundle'
        );
        insert testMedicationCodeBundle;
        
        MedicationRequest medReq = new MedicationRequest(
            PatientId = patient.Id,
            Status = 'Active',
            Type = 'MedicationRequest',
            MedicationCodeId = testMedicationCodeBundle.Id
        );
        insert medReq;
        medicationRequestId = medReq.Id;
    }

    @isTest
    static void testQueueable_SuccessfulFlow_CreatesCaseAndUpdatesRequest() {
        Account patient = [SELECT Id, FirstName, LastName, PersonBirthdate, PersonGender FROM Account WHERE FirstName = 'John' AND LastName = 'Patient' LIMIT 1];
        MemberPlan plan = [SELECT Id, MemberId, MemberNumber, GroupNumber FROM MemberPlan WHERE MemberId = :patient.Id LIMIT 1];
        Contact provider = [SELECT Id, FirstName, LastName FROM Contact WHERE FirstName = 'Dr. Emily' AND LastName = 'Carter' LIMIT 1];

        CareBenefitVerifyRequest requestToProcess = new CareBenefitVerifyRequest(
            MemberPlanId = plan.Id,
            Status = 'Pending'
        );
        insert requestToProcess;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'OK', '{"status": "Completed", "statusReason": "Success"}'));

        BenefitsVerificationService.QueueableData data = new BenefitsVerificationService.QueueableData();
        data.requestsToProcess = new List<CareBenefitVerifyRequest>{ requestToProcess };
        data.patientAccounts = new Map<Id, Account>{ patient.Id => patient };
        data.providerContacts = new Map<Id, Contact>{ provider.Id => provider };
        data.providerNpis = new Map<Id, String>{ provider.Id => '1234567890' };
        data.patientToPractitioner = new Map<Id, Id>{ patient.Id => provider.Id };
        data.memberPlanMap = new Map<Id, MemberPlan>{ plan.Id => plan };

        Test.startTest();
        System.enqueueJob(new BenefitsVerificationService.BenefitVerificationCalloutQueueable(data));
        Test.stopTest();

        CareBenefitVerifyRequest updated = [SELECT Id, Status, StatusReason, CaseId FROM CareBenefitVerifyRequest WHERE Id = :requestToProcess.Id LIMIT 1];
        System.assertEquals('Completed', updated.Status, 'Status should be updated from success response');
        System.assertEquals('Success', updated.StatusReason, 'StatusReason should reflect success');
        System.assertNotEquals(null, updated.CaseId, 'CaseId should be populated after case creation and linking');

        List<Case> createdCases = [SELECT Id, AccountId, Subject FROM Case WHERE AccountId = :patient.Id AND Subject LIKE 'Benefit Verification Acknowledged for %'];
        System.assertEquals(1, createdCases.size(), 'One success case should be created');
    }

    @isTest
    static void testQueueable_FailedFlow_CreatesErrorCase() {
        Account patient = [SELECT Id, FirstName, LastName FROM Account WHERE FirstName = 'John' AND LastName = 'Patient' LIMIT 1];
        MemberPlan plan = [SELECT Id, MemberId, MemberNumber, GroupNumber FROM MemberPlan WHERE MemberId = :patient.Id LIMIT 1];
        Contact provider = [SELECT Id, FirstName, LastName FROM Contact WHERE FirstName = 'Dr. Emily' AND LastName = 'Carter' LIMIT 1];

        CareBenefitVerifyRequest requestToProcess = new CareBenefitVerifyRequest(
            MemberPlanId = plan.Id,
            Status = 'Pending'
        );
        insert requestToProcess;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, 'Server Error', 'Internal Server Error'));

        BenefitsVerificationService.QueueableData data = new BenefitsVerificationService.QueueableData();
        data.requestsToProcess = new List<CareBenefitVerifyRequest>{ requestToProcess };
        data.patientAccounts = new Map<Id, Account>{ patient.Id => patient };
        data.providerContacts = new Map<Id, Contact>{ provider.Id => provider };
        data.providerNpis = new Map<Id, String>{ provider.Id => '1234567890' };
        data.patientToPractitioner = new Map<Id, Id>{ patient.Id => provider.Id };
        data.memberPlanMap = new Map<Id, MemberPlan>{ plan.Id => plan };

        Test.startTest();
        System.enqueueJob(new BenefitsVerificationService.BenefitVerificationCalloutQueueable(data));
        Test.stopTest();

        CareBenefitVerifyRequest updated = [SELECT Id, Status, StatusReason FROM CareBenefitVerifyRequest WHERE Id = :requestToProcess.Id LIMIT 1];
        System.assertEquals('Error', updated.Status, 'Status should be Error for non-200 responses');
        System.assertNotEquals(null, updated.StatusReason, 'StatusReason should be populated for errors');

        List<Case> errorCases = [SELECT Id, AccountId, Subject, Description FROM Case WHERE AccountId = :plan.MemberId AND Subject = 'Failed to Verify Benefits'];
        System.assertEquals(1, errorCases.size(), 'One error case should be created');
    }

    private class ThrowingHttpMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new BenefitsVerificationService.BenefitVerificationException('Simulated callout failure');
        }
    }

    @isTest
    static void testQueueable_ExceptionDuringCallout_CreatesErrorCase() {
        Account patient = [SELECT Id FROM Account WHERE FirstName = 'John' AND LastName = 'Patient' LIMIT 1];
        MemberPlan plan = [SELECT Id, MemberId FROM MemberPlan WHERE MemberId = :patient.Id LIMIT 1];
        Contact provider = [SELECT Id FROM Contact WHERE FirstName = 'Dr. Emily' AND LastName = 'Carter' LIMIT 1];

        CareBenefitVerifyRequest requestToProcess = new CareBenefitVerifyRequest(
            MemberPlanId = plan.Id,
            Status = 'Pending'
        );
        insert requestToProcess;

        Test.setMock(HttpCalloutMock.class, new ThrowingHttpMock());

        BenefitsVerificationService.QueueableData data = new BenefitsVerificationService.QueueableData();
        data.requestsToProcess = new List<CareBenefitVerifyRequest>{ requestToProcess };
        data.patientAccounts = new Map<Id, Account>{ patient.Id => patient };
        data.providerContacts = new Map<Id, Contact>{ provider.Id => provider };
        data.providerNpis = new Map<Id, String>{ provider.Id => '1234567890' };
        data.patientToPractitioner = new Map<Id, Id>{ patient.Id => provider.Id };
        data.memberPlanMap = new Map<Id, MemberPlan>{ plan.Id => plan };

        Test.startTest();
        System.enqueueJob(new BenefitsVerificationService.BenefitVerificationCalloutQueueable(data));
        Test.stopTest();

        CareBenefitVerifyRequest updated = [SELECT Id, Status, StatusReason FROM CareBenefitVerifyRequest WHERE Id = :requestToProcess.Id LIMIT 1];
        System.assertEquals('Error', updated.Status, 'Status should be Error when exception occurs');

        List<Case> errorCases = [SELECT Id, AccountId, Subject, Description FROM Case WHERE AccountId = :plan.MemberId AND Subject = 'Failed to Verify Benefits'];
        System.assertEquals(1, errorCases.size(), 'Error case should be created for exception path');
    }

    @isTest
    static void testQueueable_MultipleSuccessRequests_UpdateRequestsAndCases() {
        Account patient = [SELECT Id, FirstName, LastName, PersonBirthdate, PersonGender FROM Account WHERE FirstName = 'John' AND LastName = 'Patient' LIMIT 1];
        MemberPlan plan = [SELECT Id, MemberId, MemberNumber, GroupNumber FROM MemberPlan WHERE MemberId = :patient.Id LIMIT 1];
        Contact provider = [SELECT Id, FirstName, LastName FROM Contact WHERE FirstName = 'Dr. Emily' AND LastName = 'Carter' LIMIT 1];

        CareBenefitVerifyRequest r1 = new CareBenefitVerifyRequest(MemberPlanId = plan.Id, Status = 'Pending');
        CareBenefitVerifyRequest r2 = new CareBenefitVerifyRequest(MemberPlanId = plan.Id, Status = 'Pending');
        insert new List<CareBenefitVerifyRequest>{ r1, r2 };

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, 'OK', '{"status": "Completed", "statusReason": "Success"}'));

        BenefitsVerificationService.QueueableData data = new BenefitsVerificationService.QueueableData();
        data.requestsToProcess = new List<CareBenefitVerifyRequest>{ r1, r2 };
        data.patientAccounts = new Map<Id, Account>{ patient.Id => patient };
        data.providerContacts = new Map<Id, Contact>{ provider.Id => provider };
        data.providerNpis = new Map<Id, String>{ provider.Id => '1234567890' };
        data.patientToPractitioner = new Map<Id, Id>{ patient.Id => provider.Id };
        data.memberPlanMap = new Map<Id, MemberPlan>{ plan.Id => plan };

        Test.startTest();
        System.enqueueJob(new BenefitsVerificationService.BenefitVerificationCalloutQueueable(data));
        Test.stopTest();

        List<CareBenefitVerifyRequest> updated = [SELECT Id, Status, StatusReason, CaseId FROM CareBenefitVerifyRequest WHERE Id IN :new List<Id>{ r1.Id, r2.Id }];
        System.assertEquals(2, updated.size(), 'Two requests should be updated');
        for (CareBenefitVerifyRequest r : updated) {
            System.assertEquals('Completed', r.Status);
            System.assertEquals('Success', r.StatusReason);
            System.assertNotEquals(null, r.CaseId);
        }
    }

    @isTest
    static void testVerifyBenefits_MissingActivePlan_CreatesErrorCase_ForNewPatient() {
        Account newPatient = new Account(
            FirstName = 'Alice',
            LastName = 'Patient',
            PersonBirthdate = Date.newInstance(1990, 1, 1),
            PersonGender = 'Female'
        );
        insert newPatient;

        Test.startTest();
        BenefitsVerificationService.verifyBenefits(new List<Id>{ newPatient.Id });
        Test.stopTest();

        List<Case> errorCases = [SELECT Id, AccountId, Subject, Description FROM Case WHERE AccountId = :newPatient.Id AND Subject = 'Failed to Verify Benefits'];
        System.assertEquals(1, errorCases.size(), 'Error case should be created when active plan is missing');
        System.assert(errorCases[0].Description.contains('missing an active plan'), 'Description should mention missing active plan');
    }

    @isTest
    static void testVerifyBenefits_MissingPractitioner_CreatesErrorCase_ForNewPatientWithPlan() {
        Account newPatient = new Account(
            FirstName = 'Bob',
            LastName = 'Patient',
            PersonBirthdate = Date.newInstance(1992, 2, 2),
            PersonGender = 'Male'
        );
        insert newPatient;

        MemberPlan activePlan = new MemberPlan(
            Name = 'Active Plan for Bob',
            MemberId = newPatient.Id,
            MemberNumber = 'BOB123',
            GroupNumber = 'GRPBOB',
            Status = 'Active'
        );
        insert activePlan;

        Test.startTest();
        BenefitsVerificationService.verifyBenefits(new List<Id>{ newPatient.Id });
        Test.stopTest();

        List<Case> errorCases = [SELECT Id, AccountId, Subject, Description FROM Case WHERE AccountId = :newPatient.Id AND Subject = 'Failed to Verify Benefits'];
        System.assertEquals(1, errorCases.size(), 'Error case should be created when PCP is missing');
        System.assert(errorCases[0].Description.contains('missing a designated Primary Care Provider'), 'Description should mention missing PCP');
    }
}