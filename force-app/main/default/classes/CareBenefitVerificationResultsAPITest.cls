/**
 * @description Test class for CareBenefitVerificationResultsAPI
 */
@isTest
private class CareBenefitVerificationResultsAPITest {

    private static String memberNumber = 'MEM12345';
    private static String groupNumber = 'GRP67890';

    /**
     * @description Create test data setup
     */
    @testSetup
    static void makeData() {
        Account member = new Account(Name = 'John Doe');
        insert member;

        MemberPlan memberPlan = new MemberPlan(
            Name = 'Test Member Plan',
            MemberId = member.Id,
            MemberNumber = memberNumber,
            GroupNumber = groupNumber
        );
        insert memberPlan;

        CareBenefitVerifyRequest cbvr = new CareBenefitVerifyRequest(
            MemberPlanId = memberPlan.Id,
            Status = 'Acknowledged'
        );
        insert cbvr;
    }

    @isTest
    static void testHandleBenefitVerificationResults_WithValidPayload_ProcessesSuccessfully() {
        CareBenefitVerifyRequest cbvr = [SELECT Id, Status, StatusReason FROM CareBenefitVerifyRequest LIMIT 1];
        
        String payload = buildTestPayload(cbvr.Id, false, false);
        RestRequest req = createRestRequest(payload);

        Test.startTest();
        CareBenefitVerificationResultsAPI.APIResponse res = CareBenefitVerificationResultsAPI.handleBenefitVerificationResults();
        Test.stopTest();

        System.assertEquals(true, res.success, 'Response should be successful.');
        System.assertNotEquals(null, res.coverageBenefitId, 'Should return CoverageBenefit ID.');

        // Verify CoverageBenefit was created
        List<CoverageBenefit> benefits = [SELECT Id, CareBenefitVerifyRequestId FROM CoverageBenefit WHERE Id = :res.coverageBenefitId];
        System.assertEquals(1, benefits.size(), 'A CoverageBenefit should be created.');
        System.assertEquals(cbvr.Id, benefits[0].CareBenefitVerifyRequestId, 'CoverageBenefit should be linked to the request.');

        // Verify CareBenefitVerifyRequest was updated
        CareBenefitVerifyRequest updatedRequest = [SELECT Id, Status, StatusReason FROM CareBenefitVerifyRequest WHERE Id = :cbvr.Id];
        System.assertEquals('Completed', updatedRequest.Status, 'Request status should be updated to Completed.');
        System.assertEquals('Benefit verification completed successfully', updatedRequest.StatusReason, 'Status reason should indicate successful completion.');
    }

    @isTest
    static void testHandleBenefitVerificationResults_WithValidPayload_UpdatesCareBenefitVerifyRequest() {
        CareBenefitVerifyRequest cbvr = [SELECT Id, Status, StatusReason FROM CareBenefitVerifyRequest LIMIT 1];
        
        // Verify initial state (status might be different based on setup)
        System.assertNotEquals('Completed', cbvr.Status, 'Initial status should not be Completed.');
        
        String payload = buildTestPayload(cbvr.Id, false, false);
        RestRequest req = createRestRequest(payload);

        Test.startTest();
        CareBenefitVerificationResultsAPI.APIResponse res = CareBenefitVerificationResultsAPI.handleBenefitVerificationResults();
        Test.stopTest();

        // Verify CareBenefitVerifyRequest was properly updated
        CareBenefitVerifyRequest updatedRequest = [SELECT Id, Status, StatusReason FROM CareBenefitVerifyRequest WHERE Id = :cbvr.Id];
        System.assertEquals('Completed', updatedRequest.Status, 'Request status should be updated to Completed.');
        System.assertEquals('Benefit verification completed successfully', updatedRequest.StatusReason, 'Status reason should indicate successful completion.');
        
        // Verify CoverageBenefit was created and linked
        List<CoverageBenefit> benefits = [SELECT Id, CareBenefitVerifyRequestId FROM CoverageBenefit WHERE Id = :res.coverageBenefitId];
        System.assertEquals(1, benefits.size(), 'A CoverageBenefit should be created.');
        System.assertEquals(cbvr.Id, benefits[0].CareBenefitVerifyRequestId, 'CoverageBenefit should be linked to the request.');
    }

    @isTest
    static void testHandleBenefitVerificationResults_WithExternalErrorResponse_ProcessesSuccessfully() {
        CareBenefitVerifyRequest cbvr = [SELECT Id FROM CareBenefitVerifyRequest LIMIT 1];
        
        String errorPayload = buildTestPayload(cbvr.Id, true, false);
        RestRequest req = createRestRequest(errorPayload);

        Test.startTest();
        CareBenefitVerificationResultsAPI.APIResponse res = CareBenefitVerificationResultsAPI.handleBenefitVerificationResults();
        Test.stopTest();

        System.assertEquals(true, res.success, 'Response should be successful even with error.');
        System.assertNotEquals(null, res.coverageBenefitId, 'CoverageBenefitId should not be null.');

        List<CoverageBenefit> benefits = [SELECT Id FROM CoverageBenefit];
        System.assertEquals(1, benefits.size(), 'A CoverageBenefit should still be created.');

        CareBenefitVerifyRequest updatedRequest = [SELECT Id, Status, StatusReason FROM CareBenefitVerifyRequest WHERE Id = :cbvr.Id];
        System.assertEquals('Completed', updatedRequest.Status, 'Request Status should be Completed.');
        System.assert(updatedRequest.StatusReason.contains('Error:'), 'StatusReason should contain error message.');
    }

    @isTest
    static void testHandleBenefitVerificationResults_WithMissingRequiredField_ReturnsError() {
        String invalidPayload = buildTestPayload(null, false, false);
        RestRequest req = createRestRequest(invalidPayload);

        Test.startTest();
        CareBenefitVerificationResultsAPI.APIResponse res = CareBenefitVerificationResultsAPI.handleBenefitVerificationResults();
        Test.stopTest();

        System.assertEquals(false, res.success, 'Response should indicate failure.');
        System.assertEquals('API Error: benefitsRequestId is required', res.message, 'Error message is incorrect.');
        System.assertEquals(null, res.coverageBenefitId, 'CoverageBenefitId should be null.');
        System.assertEquals(1, res.errors.size(), 'There should be one error.');
        System.assertEquals('benefitsRequestId is required', res.errors[0], 'Error message should match.');

        List<CoverageBenefit> benefits = [SELECT Id FROM CoverageBenefit];
        System.assertEquals(0, benefits.size(), 'No CoverageBenefit records should be created.');
    }

    @isTest
    static void testHandleBenefitVerificationResults_WithInvalidRequestId_ReturnsError() {
        String invalidPayload = buildTestPayload('INVALID_ID_123', false, false);
        RestRequest req = createRestRequest(invalidPayload);

        Test.startTest();
        CareBenefitVerificationResultsAPI.APIResponse res = CareBenefitVerificationResultsAPI.handleBenefitVerificationResults();
        Test.stopTest();

        System.assertEquals(false, res.success, 'Response should indicate failure.');
        System.assertEquals('API Error: CareBenefitVerifyRequest not found with ID: INVALID_ID_123', res.message, 'Error message is incorrect.');
        System.assertEquals(null, res.coverageBenefitId, 'CoverageBenefitId should be null.');
        System.assertEquals(1, res.errors.size(), 'There should be one error.');

        List<CoverageBenefit> benefits = [SELECT Id FROM CoverageBenefit];
        System.assertEquals(0, benefits.size(), 'No CoverageBenefit records should be created.');
    }

    @isTest
    static void testHandleBenefitVerificationResults_WithDateParsing_HandlesValidDates() {
        CareBenefitVerifyRequest cbvr = [SELECT Id FROM CareBenefitVerifyRequest LIMIT 1];
        
        String payloadWithDates = buildTestPayload(cbvr.Id, false, true);
        RestRequest req = createRestRequest(payloadWithDates);

        Test.startTest();
        CareBenefitVerificationResultsAPI.APIResponse res = CareBenefitVerificationResultsAPI.handleBenefitVerificationResults();
        Test.stopTest();

        System.assertEquals(true, res.success, 'Response should be successful.');

        List<CoverageBenefit> benefits = [SELECT Id, BenefitPeriodStartDate, BenefitPeriodEndDate FROM CoverageBenefit];
        System.assertEquals(1, benefits.size(), 'A CoverageBenefit should still be created.');
        System.assertEquals(Date.newInstance(2024, 1, 1), benefits[0].BenefitPeriodStartDate, 'Start date should be parsed correctly.');
        System.assertEquals(Date.newInstance(2024, 12, 31), benefits[0].BenefitPeriodEndDate, 'End date should be parsed correctly.');
    }

    @isTest
    static void testHandleBenefitVerificationResults_WithMalformedJson_ReturnsError() {
        CareBenefitVerifyRequest cbvr = [SELECT Id FROM CareBenefitVerifyRequest LIMIT 1];
        
        // Create malformed JSON (missing comma)
        String malformedPayload = '{"benefitsRequestId": "' + cbvr.Id + '" "isCoverageActive": true}';
        RestRequest req = createRestRequest(malformedPayload);

        Test.startTest();
        CareBenefitVerificationResultsAPI.APIResponse res = CareBenefitVerificationResultsAPI.handleBenefitVerificationResults();
        Test.stopTest();

        System.assertEquals(false, res.success, 'Response should be unsuccessful.');
        System.assert(res.message.contains('Unexpected error'), 'Error message should indicate an unexpected error.');
        System.assert(res.errors.size() > 0, 'Should have error details.');
        
        // Debug: Print the actual error message
        System.debug('Actual error message: ' + res.errors[0]);
        
        System.assert(res.errors[0].contains('JSON') || res.errors[0].contains('deserialize') || res.errors[0].contains('parse') || res.errors[0].contains('Unexpected'), 'Error detail should mention JSON parsing error. Actual error: ' + res.errors[0]);
    }

    /**
     * @description Build test payload for API testing
     */
    private static String buildTestPayload(String benefitsRequestId, Boolean includeError, Boolean includeDates) {
        Map<String, Object> payload = new Map<String, Object>();
        
        if (benefitsRequestId != null) {
            payload.put('benefitsRequestId', benefitsRequestId);
        }
        
        payload.put('memberNumber', 'MEM12345');
        payload.put('groupNumber', 'GRP67890');
        payload.put('isCoverageActive', true);
        
        if (includeDates) {
            payload.put('benefitPeriodStartDate', '2024/01/01');
            payload.put('benefitPeriodEndDate', '2024/12/31');
        }
        
        if (includeError) {
            payload.put('errorResponse', 'External system error: Invalid member number');
        } else {
            payload.put('errorResponse', '');
        }
        
        payload.put('jsonResponse', '{"status": "success", "message": "Benefits verified successfully"}');
        payload.put('benefitNotes', 'Comprehensive health benefits coverage');
        payload.put('coinsuranceNotes', '20% coinsurance after deductible');
        payload.put('copayNotes', 'Standard copay structure');
        payload.put('deductibleNotes', 'Annual deductible applies');
        payload.put('disclaimer', 'Benefits subject to change');
        payload.put('lifetimeMaximumNotes', 'No lifetime maximum');
        payload.put('outofPocketNotes', 'Out-of-pocket maximum applies');
        
        payload.put('emergencyDepartmentCopay', 150.00);
        payload.put('pharmaCopayAmount', 10.00);
        payload.put('primaryCareCopay', 25.00);
        payload.put('specialistCopay', 40.00);
        payload.put('urgentCareCopay', 50.00);
        
        payload.put('inNetworkCoinsuranceAmount', 0.00);
        payload.put('inNetworkCoinsurancePercentage', 20.0);
        payload.put('inNetworkLifetimeMaximum', 5000000);
        
        payload.put('outofNetworkCoinsuranceAmount', 0.00);
        payload.put('outofNetworkCoinsurancePercentage', 40.0);
        payload.put('outofNetworkLifetimeMaximum', 0.00);
        
        payload.put('individualInNetworkDeductibleApplied', 0.00);
        payload.put('individualInNetworkDeductibleLimit', 1500.00);
        payload.put('individualInNetworkDeductibleRemaining', 1500.00);
        
        payload.put('individualInNetworkOutofPocketApplied', 0.00);
        payload.put('individualInNetworkOutofPocketLimit', 3000.00);
        payload.put('individualInNetworkOutofPocketRemaining', 3000.00);
        
        payload.put('individualOutofNetworkDeductibleApplied', 0.00);
        payload.put('individualOutofNetworkDeductibleLimit', 3000.00);
        payload.put('individualOutofNetworkDeductibleRemain', 3000.00);
        
        payload.put('individualOutofNetworkOutofPocketApplied', 0.00);
        payload.put('individualOutofNetworkOutofPocketLimit', 6000.00);
        payload.put('individualOutofNetworkOutofPocketRemain', 6000.00);
        
        payload.put('familyInNetworkDeductibleApplied', 0.00);
        payload.put('familyInNetworkDeductibleLimit', 3000.00);
        payload.put('familyInNetworkDeductibleRemaining', 3000.00);
        
        payload.put('familyInNetworkOutofPocketApplied', 0.00);
        payload.put('familyInNetworkOutofPocketLimit', 6000.00);
        payload.put('familyInNetworkOutofPocketRemaining', 6000.00);
        
        payload.put('familyOutofNetworkDeductibleApplied', 0.00);
        payload.put('familyOutofNetworkDeductibleLimit', 6000.00);
        payload.put('familyOutofNetworkDeductibleRemaining', 6000.00);
        
        payload.put('familyOutofNetworkOutofPocketApplied', 0.00);
        payload.put('familyOutofNetworkOutofPocketLimit', 12000.00);
        payload.put('familyOutofNetworkOutofPocketRemaining', 12000.00);
        
        List<Map<String, Object>> benefitsItems = new List<Map<String, Object>>();
        Map<String, Object> benefitItem = new Map<String, Object>();
        benefitItem.put('serviceType', 'Inpatient Hospitalization');
        benefitItem.put('serviceTypeCode', 'INPATIENT_HOSP');
        benefitItem.put('benefitsCategory', 'Medical');
        benefitItem.put('notes', 'Inpatient hospital services');
        benefitItem.put('inPlanNetworkIndicator', true);
        
        List<Map<String, Object>> itemLimits = new List<Map<String, Object>>();
        Map<String, Object> itemLimit = new Map<String, Object>();
        itemLimit.put('benefitCode', 'COINSURANCE');
        itemLimit.put('benefitValue', '20%');
        itemLimit.put('benefitMetricType', 'Percentage');
        itemLimit.put('coverageLevel', 'Individual');
        itemLimit.put('limitNotes', '20% coinsurance after deductible');
        itemLimit.put('termType', 'Day');
        itemLimit.put('networkType', 'IN');
        itemLimits.add(itemLimit);
        
        benefitItem.put('benefitsItemLimit', itemLimits);
        benefitsItems.add(benefitItem);
        
        payload.put('benefitsItem', benefitsItems);
        
        return JSON.serialize(payload);
    }

    /**
     * @description Create REST request for testing
     */
    private static RestRequest createRestRequest(String body) {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        return req;
    }
}