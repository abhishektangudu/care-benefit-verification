/**
 * @description Benefit Verification Service - Handles benefit verification workflow
 */
public with sharing class BenefitsVerificationService {

    /**
     * @description Main entry point for benefit verification workflow
     */
    @InvocableMethod(label='Verify Benefits' description='Queries patient data, calls an external API, and creates a verification Case.')
    public static void verifyBenefits(List<Id> patientAccountIds) {
        // Query patient data
        List<Account> patients = [
            SELECT Id, FirstName, LastName, PersonContactId, PersonBirthdate, PersonGender 
            FROM Account 
            WHERE Id IN :patientAccountIds
            WITH USER_MODE
        ];
        
        // Query active member plans
        List<MemberPlan> activePlans = [
            SELECT Id, MemberId, GroupNumber, MemberNumber, PayerId
            FROM MemberPlan 
            WHERE MemberId IN :patientAccountIds AND Status = 'Active'
            WITH USER_MODE
        ];
        
        // Build patient to plan mapping
        Map<Id, MemberPlan> patientToActivePlan = new Map<Id, MemberPlan>();
        for (MemberPlan plan : activePlans) {
            patientToActivePlan.put(plan.MemberId, plan);
        }
        
        // Query provider relationships
        Set<Id> patientContactIds = new Set<Id>();
        for (Account patient : patients) {
            if (patient.PersonContactId != null) {
                patientContactIds.add(patient.PersonContactId);
            }
        }
        
        Map<Id, Id> patientToPractitioner = new Map<Id, Id>();
        if (!patientContactIds.isEmpty()) {
            List<ContactContactRelation> patientContactRelations = [
                SELECT RelatedContactId, Contact.AccountId 
                FROM ContactContactRelation 
                WHERE PartyRoleRelation.RelatedRoleName = 'PCP' AND ContactId IN :patientContactIds
                WITH USER_MODE
            ];
            
            for (ContactContactRelation relation : patientContactRelations) {
                patientToPractitioner.put(relation.Contact.AccountId, relation.RelatedContactId);
            }
        }
        
        // Query provider data
        List<Id> practitionerIds = patientToPractitioner.values();
        Map<Id, Contact> providerContacts = new Map<Id, Contact>();
        Map<Id, String> providerNpis = new Map<Id, String>();
        Map<Id, HealthcareProvider> practitionerProviders = new Map<Id, HealthcareProvider>();
        
        if (!practitionerIds.isEmpty()) {
            List<Contact> providers = [
                SELECT Id, FirstName, LastName,
                       (SELECT Id, Npi FROM HealthcareProviderNPIs WHERE IsActive = true LIMIT 1), 
                       (SELECT Id FROM HealthcareProviders LIMIT 1)
                FROM Contact 
                WHERE Id IN :practitionerIds
                WITH USER_MODE
            ];
            
            for (Contact provider : providers) {
                if (provider.HealthcareProviders != null && !provider.HealthcareProviders.isEmpty()) {
                    practitionerProviders.put(provider.Id, provider.HealthcareProviders[0]);
                }
                if (provider.HealthcareProviderNPIs != null && !provider.HealthcareProviderNPIs.isEmpty()) {
                    providerNpis.put(provider.Id, provider.HealthcareProviderNPIs[0].Npi);
                }
                providerContacts.put(provider.Id, provider);
            }
        }
        
        // Create benefit verification requests
        List<CareBenefitVerifyRequest> requestsToInsert = new List<CareBenefitVerifyRequest>();
        List<Case> errorCasesToInsert = new List<Case>();
        
        for (Id patientId : patientAccountIds) {
            try {
                MemberPlan activePlan = patientToActivePlan.get(patientId);
                if (activePlan == null) {
                    throw new BenefitVerificationException('Patient is missing an active plan.');
                }
                
                Id practitionerId = patientToPractitioner.get(patientId);
                if (practitionerId == null) {
                    throw new BenefitVerificationException('Patient is missing a designated Primary Care Provider.');
                }
                
                HealthcareProvider practitionerProvider = practitionerProviders.get(practitionerId);
                if (practitionerProvider == null) {
                    throw new BenefitVerificationException('Patient is missing a designated Primary Care Provider.');
                }
                
                CareBenefitVerifyRequest newRequest = new CareBenefitVerifyRequest();
                newRequest.MemberPlanId = activePlan.Id;
                newRequest.PayerId = activePlan.PayerId;
                newRequest.ProviderId = practitionerProvider.Id;
                newRequest.RequesterId = practitionerProvider.Id;
                newRequest.RequestDate = System.now();
                newRequest.RequestedById = UserInfo.getUserId();
                newRequest.Status = 'Pending';
                newRequest.StatusReason = 'Benefit verification request created';
                
                requestsToInsert.add(newRequest);

            } catch (Exception e) {
                Case errorCase = createErrorCase(patientId, e.getMessage());
                errorCasesToInsert.add(errorCase);
            }
        }
        
        // Insert requests and error cases
        if (!requestsToInsert.isEmpty()) {
            insert requestsToInsert;
        }
        
        if (!errorCasesToInsert.isEmpty()) {
            insert errorCasesToInsert;
        }
        
        // Queue asynchronous API callouts
        if (!requestsToInsert.isEmpty()) {
            // Build member plan map keyed by MemberPlanId for queueable
            Map<Id, MemberPlan> memberPlanMap = new Map<Id, MemberPlan>(activePlans);
            
            QueueableData data = new QueueableData();
            data.requestsToProcess = requestsToInsert;
            data.patientAccounts = new Map<Id, Account>(patients);
            data.providerContacts = providerContacts;
            data.providerNpis = providerNpis;
            data.patientToPractitioner = patientToPractitioner;
            data.memberPlanMap = memberPlanMap;
            
            System.enqueueJob(new BenefitVerificationCalloutQueueable(data));
        }
    }
    
    /**
     * @description Data container for queueable job
     */
    public class QueueableData {
        @TestVisible public List<CareBenefitVerifyRequest> requestsToProcess;
        @TestVisible public Map<Id, Account> patientAccounts;
        @TestVisible public Map<Id, Contact> providerContacts;
        @TestVisible public Map<Id, String> providerNpis;
        @TestVisible public Map<Id, Id> patientToPractitioner;
        @TestVisible public Map<Id, MemberPlan> memberPlanMap;
    }
    
    /**
     * @description Asynchronous job to handle API callouts
     */
    public class BenefitVerificationCalloutQueueable implements Queueable, Database.AllowsCallouts {
        
        private QueueableData data;
        
        public BenefitVerificationCalloutQueueable(QueueableData queueableData) {
            this.data = queueableData;
        }
        
        public void execute(QueueableContext context) {
            // Process API callouts for each request
            List<CareBenefitVerifyRequest> requestsToUpdate = new List<CareBenefitVerifyRequest>();
            List<Case> casesToInsert = new List<Case>();
            List<Case> errorCasesToInsert = new List<Case>();
            
            for (CareBenefitVerifyRequest request : data.requestsToProcess) {
                try {
                    // Get member plan from the passed map using MemberPlanId
                    MemberPlan memberPlan = data.memberPlanMap.get(request.MemberPlanId);
                    if (memberPlan == null) {
                        continue;
                    }
                    
                    Id patientId = memberPlan.MemberId;
                    Account patient = data.patientAccounts.get(patientId);
                    if (patient == null) {
                        continue;
                    }
                    
                    Id practitionerId = data.patientToPractitioner.get(patientId);
                    if (practitionerId == null) {
                        continue;
                    }
                    
                    Contact providerContact = data.providerContacts.get(practitionerId);
                    String providerNpi = data.providerNpis.get(practitionerId);
                    
                    if (providerContact == null) {
                        continue;
                    }
                    
                    // Execute API callout
                    BenefitVerificationRequestPayload payload = buildPayload(patient, memberPlan, providerContact, providerNpi);
                    payload.benefitRequestId = request.Id;
                    
                    HttpRequest httpReq = createHttpRequest(JSON.serialize(payload));
                    HttpResponse httpRes = new Http().send(httpReq);

                    if (httpRes.getStatusCode() == 200) {
                        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(httpRes.getBody());
                        
                        request.Status = (String) responseMap.get('status');
                        request.StatusReason = (String) responseMap.get('statusReason');
                        requestsToUpdate.add(request);
                        
                        Case verificationCase = createCase(request, patientId);
                        casesToInsert.add(verificationCase);
                        
                    } else {
                        request.Status = 'Error';
                        request.StatusReason = 'API Error: ' + httpRes.getStatusCode() + ' - ' + httpRes.getStatus();
                        requestsToUpdate.add(request);
                        
                        Case errorCase = createErrorCase(patientId, 'API Error: ' + httpRes.getStatusCode() + ' - ' + httpRes.getStatus());
                        errorCasesToInsert.add(errorCase);
                    }
                    
                } catch (Exception e) {
                    request.Status = 'Error';
                    request.StatusReason = 'Exception: ' + e.getMessage();
                    requestsToUpdate.add(request);
                    
                    // Get member plan for error case
                    MemberPlan memberPlan = data.memberPlanMap.get(request.MemberPlanId);
                    if (memberPlan != null) {
                        Case errorCase = createErrorCase(memberPlan.MemberId, e.getMessage());
                        errorCasesToInsert.add(errorCase);
                    }
                }
            }
            
            // Update requests
            if (!requestsToUpdate.isEmpty()) {
                update requestsToUpdate;
            }

            // Create cases with assignment rules
            if (!casesToInsert.isEmpty() || !errorCasesToInsert.isEmpty()) {
                try {
                    List<AssignmentRule> assignmentRules = [
                        SELECT Id FROM AssignmentRule 
                        WHERE SobjectType = 'Case' AND Active = true 
                        LIMIT 1
                    ];
                    
                    Database.DMLOptions dmlOpts = new Database.DMLOptions();
                    if (!assignmentRules.isEmpty()) {
                        dmlOpts.assignmentRuleHeader.assignmentRuleId = assignmentRules[0].Id;
                    }
                    
                    // Insert cases
                    if (!casesToInsert.isEmpty()) {
                        Database.insert(casesToInsert, dmlOpts);
                    }
                    
                    if (!errorCasesToInsert.isEmpty()) {
                        Database.insert(errorCasesToInsert, dmlOpts);
                    }
                    
                    // Update requests with case IDs
                    updateRequestsWithCaseIds(requestsToUpdate, casesToInsert);
                    
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error in case creation process: ' + e.getMessage());
                    // Fallback to simple insert
                    if (!casesToInsert.isEmpty()) {
                        insert casesToInsert;
                    }
                    if (!errorCasesToInsert.isEmpty()) {
                        insert errorCasesToInsert;
                    }
                    updateRequestsWithCaseIds(requestsToUpdate, casesToInsert);
                }
            }
        }
    }

    /**
     * @description Update CareBenefitVerifyRequest records with Case IDs
     */
    private static void updateRequestsWithCaseIds(List<CareBenefitVerifyRequest> requests, List<Case> cases) {
        Map<Id, Case> requestToCaseMap = new Map<Id, Case>();
        
        for (Case verificationCase : cases) {
            String subject = verificationCase.Subject;
            if (subject.contains('Benefit Verification Acknowledged for ')) {
                String requestId = subject.substringAfter('Benefit Verification Acknowledged for ');
                if (requestId != null && requestId.length() == 18) {
                    requestToCaseMap.put(requestId, verificationCase);
                }
            }
        }
        
        List<CareBenefitVerifyRequest> requestsToUpdate = new List<CareBenefitVerifyRequest>();
        for (CareBenefitVerifyRequest request : requests) {
            Case linkedCase = requestToCaseMap.get(request.Id);
            if (linkedCase != null) {
                request.CaseId = linkedCase.Id;
                requestsToUpdate.add(request);
            }
        }
        
        if (!requestsToUpdate.isEmpty()) {
            update requestsToUpdate;
        }
    }

    /**
     * @description Create case for successful verification
     */
    @TestVisible
    private static Case createCase(CareBenefitVerifyRequest request, Id patientId) {
        Case verificationCase = new Case();
        verificationCase.AccountId = patientId;
        verificationCase.Subject = 'Benefit Verification Acknowledged for ' + request.Id;
        verificationCase.Status = 'New';
        verificationCase.Priority = 'Medium';
        verificationCase.Type = 'Benefit Verification';
        verificationCase.Origin = 'System';
        verificationCase.Description = 'Benefit verification request has been submitted and is being processed.';
        
        // Set record type to PreAuthorization for assignment rules
        try {
            Schema.RecordTypeInfo recordTypeInfo = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PreAuthorization');
            if (recordTypeInfo != null) {
                verificationCase.RecordTypeId = recordTypeInfo.getRecordTypeId();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not set RecordType for Case: ' + e.getMessage());
        }
        
        return verificationCase;
    }

    /**
     * @description Create error case for failed verification
     */
    @TestVisible
    private static Case createErrorCase(Id patientId, String errorMessage) {
        Case errorCase = new Case();
        errorCase.AccountId = patientId;
        errorCase.Subject = 'Failed to Verify Benefits';
        errorCase.Description = errorMessage;
        errorCase.Status = 'New';
        errorCase.Priority = 'High';
        errorCase.Type = 'Benefit Verification';
        errorCase.Origin = 'System';
        
        // Set record type to PreAuthorization for assignment rules
        try {
            Schema.RecordTypeInfo recordTypeInfo = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('PreAuthorization');
            if (recordTypeInfo != null) {
                errorCase.RecordTypeId = recordTypeInfo.getRecordTypeId();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not set RecordType for Case: ' + e.getMessage());
        }
        
        return errorCase;
    }

    /**
     * @description Build API payload from patient and plan data
     */
    @TestVisible
    private static BenefitVerificationRequestPayload buildPayload(Account patient, MemberPlan plan, Contact provider, String npi) {
        BenefitVerificationRequestPayload payload = new BenefitVerificationRequestPayload();
        
        // Set patient details
        payload.patientDetails = new PatientDetails();
        payload.patientDetails.firstName = patient.FirstName;
        payload.patientDetails.lastName = patient.LastName;
        payload.patientDetails.dateOfBirth = patient.PersonBirthdate;
        payload.patientDetails.gender = patient.PersonGender;
        
        // Set insurance information
        payload.insuranceInformation = new InsuranceInformation();
        payload.insuranceInformation.insuranceProviderName = 'Health Insurance Provider';
        payload.insuranceInformation.policyNumber = plan.MemberNumber;
        payload.insuranceInformation.groupNumber = plan.GroupNumber;
        payload.insuranceInformation.subscriberID = plan.MemberNumber;
        
        // Set provider information
        payload.providerInformation = new ProviderInformation();
        payload.providerInformation.nationalProviderIdentifier = npi;
        payload.providerInformation.firstName = provider.FirstName;
        payload.providerInformation.lastName = provider.LastName;
        
        // Set service details
        payload.serviceDetails = new ServiceDetails();
        payload.serviceDetails.serviceType = 'Benefit Verification';
        payload.serviceDetails.serviceDate = Date.today();
        
        return payload;
    }

    /**
     * @description Create HTTP request for API callout
     */
    @TestVisible
    private static HttpRequest createHttpRequest(String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Benefit_Verification_API'+'/benefit-verification-request');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        req.setBody(body);
        return req;
    }

    public class BenefitVerificationException extends Exception {}

    // Data Transfer Objects for API payload
    public class BenefitVerificationRequestPayload {
        public String benefitRequestId;
        public PatientDetails patientDetails;
        public InsuranceInformation insuranceInformation;
        public ProviderInformation providerInformation;
        public ServiceDetails serviceDetails;
    }
    public class PatientDetails {
        public String firstName; 
        public String lastName; 
        public Date dateOfBirth; 
        public String gender;
    }
    public class InsuranceInformation {
        public String insuranceProviderName; 
        public String policyNumber; 
        public String groupNumber; 
        public String subscriberID;
    }
    public class ProviderInformation {
        public String nationalProviderIdentifier; 
        public String firstName; 
        public String lastName;
    }
    public class ServiceDetails {
        public String serviceType; 
        public Date serviceDate;
    }
}