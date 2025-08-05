/**
 * @description REST API endpoint for benefit verification results
 */
@RestResource(urlMapping='/care-benefit-verification-results')
global with sharing class CareBenefitVerificationResultsAPI {
    
    public class APIException extends Exception {}
    
    /**
     * @description Request wrapper for incoming JSON
     */
    global class BenefitVerificationResult {
        public String memberNumber;
        public String groupNumber;
        public String benefitsRequestId;
        public Boolean isCoverageActive;
        public String benefitPeriodStartDate;
        public String benefitPeriodEndDate;
        public String errorResponse;
        public String jsonResponse;
        public List<BenefitsItem> benefitsItem;
        
        // CoverageBenefit fields
        public String benefitNotes;
        public String coinsuranceNotes;
        public String copayNotes;
        public String coverageType;
        public String deductibleNotes;
        public String disclaimer;
        public String lifetimeMaximumNotes;
        public String outofPocketNotes;
        
        // Copay amounts
        public Decimal emergencyDepartmentCopay;
        public Decimal pharmaCopayAmount;
        public Decimal primaryCareCopay;
        public Decimal specialistCopay;
        public Decimal urgentCareCopay;
        
        // In-Network amounts
        public Decimal inNetworkCoinsuranceAmount;
        public Decimal inNetworkCoinsurancePercentage;
        public Decimal inNetworkLifetimeMaximum;
        
        // Out-of-Network amounts
        public Decimal outofNetworkCoinsuranceAmount;
        public Decimal outofNetworkCoinsurancePercentage;
        public Decimal outofNetworkLifetimeMaximum;
        
        // Individual In-Network Deductible
        public Decimal individualInNetworkDeductibleApplied;
        public Decimal individualInNetworkDeductibleLimit;
        public Decimal individualInNetworkDeductibleRemaining;
        
        // Individual In-Network Out-of-Pocket
        public Decimal individualInNetworkOutofPocketApplied;
        public Decimal individualInNetworkOutofPocketLimit;
        public Decimal individualInNetworkOutofPocketRemaining;
        
        // Individual Out-of-Network Deductible
        public Decimal individualOutofNetworkDeductibleApplied;
        public Decimal individualOutofNetworkDeductibleLimit;
        public Decimal individualOutofNetworkDeductibleRemain;
        
        // Individual Out-of-Network Out-of-Pocket
        public Decimal individualOutofNetworkOutofPocketApplied;
        public Decimal individualOutofNetworkOutofPocketLimit;
        public Decimal individualOutofNetworkOutofPocketRemain;
        
        // Family In-Network Deductible
        public Decimal familyInNetworkDeductibleApplied;
        public Decimal familyInNetworkDeductibleLimit;
        public Decimal familyInNetworkDeductibleRemaining;
        
        // Family In-Network Out-of-Pocket
        public Decimal familyInNetworkOutofPocketApplied;
        public Decimal familyInNetworkOutofPocketLimit;
        public Decimal familyInNetworkOutofPocketRemaining;
        
        // Family Out-of-Network Deductible
        public Decimal familyOutofNetworkDeductibleApplied;
        public Decimal familyOutofNetworkDeductibleLimit;
        public Decimal familyOutofNetworkDeductibleRemaining;
        
        // Family Out-of-Network Out-of-Pocket
        public Decimal familyOutofNetworkOutofPocketApplied;
        public Decimal familyOutofNetworkOutofPocketLimit;
        public Decimal familyOutofNetworkOutofPocketRemaining;
    }
    
    /**
     * @description Benefits item structure
     */
    global class BenefitsItem {
        public String serviceType;
        public String serviceTypeCode;
        public String benefitsCategory;
        public String notes;
        public Boolean inPlanNetworkIndicator;
        public List<BenefitsItemLimit> benefitsItemLimit;
    }
    
    /**
     * @description Benefits item limit structure
     */
    global class BenefitsItemLimit {
        public String benefitCode;
        public String benefitValue;
        public String benefitMetricType;
        public String coverageLevel;
        public String limitNotes;
        public String termType;
        public String networkType;
    }
    
    /**
     * @description Response wrapper class
     */
    global class APIResponse {
        public Boolean success;
        public String message;
        public String coverageBenefitId;
        public List<String> errors;
        
        public APIResponse(Boolean success, String message) {
            this.success = success;
            this.message = message;
            this.errors = new List<String>();
        }
    }
    
    /**
     * @description Main API endpoint for benefit verification results
     */
    @HttpPost
    global static APIResponse handleBenefitVerificationResults() {
        APIResponse response = new APIResponse(false, '');
        
        try {
            String requestBody = RestContext.request.requestBody.toString();
            System.debug('Received request body: ' + requestBody);
            
            BenefitVerificationResult result = (BenefitVerificationResult) JSON.deserialize(
                requestBody, 
                BenefitVerificationResult.class
            );
            
            if (String.isBlank(result.benefitsRequestId)) {
                throw new APIException('benefitsRequestId is required');
            }
            
            String coverageBenefitId = processBenefitVerificationResult(result);
            
            response.success = true;
            response.message = 'Benefit verification result processed successfully';
            response.coverageBenefitId = coverageBenefitId;
            
        } catch (APIException e) {
            response.message = 'API Error: ' + e.getMessage();
            response.errors.add(e.getMessage());
            System.debug(LoggingLevel.ERROR, 'API Error: ' + e.getMessage());
        } catch (Exception e) {
            response.message = 'Unexpected error: ' + e.getMessage();
            response.errors.add(e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Unexpected error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        
        return response;
    }
    
    /**
     * @description Process benefit verification result and create CoverageBenefit record
     */
    private static String processBenefitVerificationResult(BenefitVerificationResult result) {
        List<CareBenefitVerifyRequest> requests = [
            SELECT Id, Status, StatusReason, MemberPlanId, MemberPlan.MemberId, MemberPlan.MemberNumber, MemberPlan.GroupNumber
            FROM CareBenefitVerifyRequest 
            WHERE Id = :result.benefitsRequestId
            LIMIT 1
        ];
        
        if (requests.isEmpty()) {
            throw new APIException('CareBenefitVerifyRequest not found with ID: ' + result.benefitsRequestId);
        }
        
        CareBenefitVerifyRequest request = requests[0];
        
        // Create CoverageBenefit record
        CoverageBenefit coverageBenefit = new CoverageBenefit();
        coverageBenefit.Name = 'Coverage Benefit - ' + request.MemberPlan.MemberNumber + ' - ' + System.now().format('MM/dd/yyyy');
        coverageBenefit.CareBenefitVerifyRequestId = result.benefitsRequestId;
        coverageBenefit.MemberId = request.MemberPlan.MemberId;
        coverageBenefit.MemberPlanId = request.MemberPlanId;
        coverageBenefit.BenefitPeriodStartDate = parseDate(result.benefitPeriodStartDate);
        coverageBenefit.BenefitPeriodEndDate = parseDate(result.benefitPeriodEndDate);
        coverageBenefit.VerificationDate = Date.today();
        coverageBenefit.IsActive = result.isCoverageActive != null ? result.isCoverageActive : true;
        
        // Map benefit fields
        coverageBenefit.BenefitNotes = result.benefitNotes;
        coverageBenefit.CoinsuranceNotes = result.coinsuranceNotes;
        coverageBenefit.CopayNotes = result.copayNotes;
        coverageBenefit.DeductibleNotes = result.deductibleNotes;
        coverageBenefit.Disclaimer = result.disclaimer;
        coverageBenefit.LifetimeMaximumNotes = result.lifetimeMaximumNotes;
        coverageBenefit.OutofPocketNotes = result.outofPocketNotes;
        
        // Map copay amounts
        coverageBenefit.EmergencyDepartmentCopay = result.emergencyDepartmentCopay;
        coverageBenefit.PharmaCopayAmount = result.pharmaCopayAmount;
        coverageBenefit.PrimaryCareCopay = result.primaryCareCopay;
        coverageBenefit.SpecialistCopay = result.specialistCopay;
        coverageBenefit.UrgentCareCopay = result.urgentCareCopay;
        
        // Map In-Network amounts
        coverageBenefit.InNetworkCoinsuranceAmount = result.inNetworkCoinsuranceAmount;
        coverageBenefit.InNetworkCoinsurancePercentage = result.inNetworkCoinsurancePercentage;
        coverageBenefit.InNetworkLifetimeMaximum = result.inNetworkLifetimeMaximum;
        
        // Map Out-of-Network amounts
        coverageBenefit.OutofNetworkCoinsuranceAmount = result.outofNetworkCoinsuranceAmount;
        coverageBenefit.OutofNetworkCoinsurancePercentage = result.outofNetworkCoinsurancePercentage;
        coverageBenefit.OutofNetworkLifetimeMaximum = result.outofNetworkLifetimeMaximum;
        
        // Map Individual In-Network Deductible
        coverageBenefit.IndividualInNetworkDeductibleApplied = result.individualInNetworkDeductibleApplied;
        coverageBenefit.IndividualInNetworkDeductibleLimit = result.individualInNetworkDeductibleLimit;
        coverageBenefit.IndividualInNetworkDeductibleRemaining = result.individualInNetworkDeductibleRemaining;
        
        // Map Individual In-Network Out-of-Pocket
        coverageBenefit.IndividualInNetworkOutofPocketApplied = result.individualInNetworkOutofPocketApplied;
        coverageBenefit.IndividualInNetworkOutofPocketLimit = result.individualInNetworkOutofPocketLimit;
        coverageBenefit.IndividualInNetworkOutofPocketRemaining = result.individualInNetworkOutofPocketRemaining;
        
        // Map Individual Out-of-Network Deductible
        coverageBenefit.IndividualOutofNetworkDeductibleApplied = result.individualOutofNetworkDeductibleApplied;
        coverageBenefit.IndividualOutofNetworkDeductibleLimit = result.individualOutofNetworkDeductibleLimit;
        coverageBenefit.IndividualOutofNetworkDeductibleRemain = result.individualOutofNetworkDeductibleRemain;
        
        // Map Individual Out-of-Network Out-of-Pocket
        coverageBenefit.IndividualOutofNetworkOutofPocketApplied = result.individualOutofNetworkOutofPocketApplied;
        coverageBenefit.IndividualOutofNetworkOutofPocketLimit = result.individualOutofNetworkOutofPocketLimit;
        coverageBenefit.IndividualOutofNetworkOutofPocketRemain = result.individualOutofNetworkOutofPocketRemain;
        
        // Map Family In-Network Deductible
        coverageBenefit.FamilyInNetworkDeductibleApplied = result.familyInNetworkDeductibleApplied;
        coverageBenefit.FamilyInNetworkDeductibleLimit = result.familyInNetworkDeductibleLimit;
        coverageBenefit.FamilyInNetworkDeductibleRemaining = result.familyInNetworkDeductibleRemaining;
        
        // Map Family In-Network Out-of-Pocket
        coverageBenefit.FamilyInNetworkOutofPocketApplied = result.familyInNetworkOutofPocketApplied;
        coverageBenefit.FamilyInNetworkOutofPocketLimit = result.familyInNetworkOutofPocketLimit;
        coverageBenefit.FamilyInNetworkOutofPocketRemaining = result.familyInNetworkOutofPocketRemaining;
        
        // Map Family Out-of-Network Deductible
        coverageBenefit.FamilyOutofNetworkDeductibleApplied = result.familyOutofNetworkDeductibleApplied;
        coverageBenefit.FamilyOutofNetworkDeductibleLimit = result.familyOutofNetworkDeductibleLimit;
        coverageBenefit.FamilyOutofNetworkDeductibleRemaining = result.familyOutofNetworkDeductibleRemaining;
        
        // Map Family Out-of-Network Out-of-Pocket
        coverageBenefit.FamilyOutofNetworkOutofPocketApplied = result.familyOutofNetworkOutofPocketApplied;
        coverageBenefit.FamilyOutofNetworkOutofPocketLimit = result.familyOutofNetworkOutofPocketLimit;
        coverageBenefit.FamilyOutofNetworkOutofPocketRemaining = result.familyOutofNetworkOutofPocketRemaining;
        
        insert coverageBenefit;
        
        // Process benefits items if provided
        if (result.benefitsItem != null && !result.benefitsItem.isEmpty()) {
            processBenefitsItems(result.benefitsItem, coverageBenefit.Id);
        }
        
        // Update CareBenefitVerifyRequest status
        request.Status = 'Completed';
        if (String.isNotBlank(result.errorResponse)) {
            request.StatusReason = 'Error: ' + result.errorResponse;
        } else {
            request.StatusReason = 'Benefit verification completed successfully';
        }
        request.put('CoverageBenefitId', coverageBenefit.Id);
        
        update request;
        
        return coverageBenefit.Id;
    }
    
    /**
     * @description Process benefits items and create CoverageBenefitItem records
     */
    private static void processBenefitsItems(List<BenefitsItem> benefitsItems, Id coverageBenefitId) {
        List<CoverageBenefitItem> itemsToInsert = new List<CoverageBenefitItem>();
        
        for (BenefitsItem item : benefitsItems) {
            CoverageBenefitItem benefitItem = new CoverageBenefitItem();
            benefitItem.Name = item.serviceTypeCode + ' - ' + item.benefitsCategory;
            benefitItem.CoverageBenefitId = coverageBenefitId;
            benefitItem.ServiceType = item.serviceType;
            benefitItem.ServiceTypeCode = item.serviceTypeCode;
            benefitItem.BenefitCategory = item.benefitsCategory;
            benefitItem.Notes = item.notes;
            benefitItem.IsInPlanNetwork = item.inPlanNetworkIndicator;
            benefitItem.IsActive = true;
            benefitItem.CoverageLevel = 'Individual';
            
            benefitItem.SourceSystem = 'External API';
            benefitItem.SourceSystemIdentifier = item.serviceTypeCode;
            benefitItem.SourceSystemModified = System.now();
            
            itemsToInsert.add(benefitItem);
        }
        
        if (!itemsToInsert.isEmpty()) {
            insert itemsToInsert;
            processBenefitsItemLimits(benefitsItems, itemsToInsert);
        }
    }
    
    /**
     * @description Process benefits item limits and create CoverageBenefitItemLimit records
     */
    private static void processBenefitsItemLimits(List<BenefitsItem> benefitsItems, List<CoverageBenefitItem> insertedItems) {
        List<CoverageBenefitItemLimit> limitsToInsert = new List<CoverageBenefitItemLimit>();
        
        for (Integer i = 0; i < benefitsItems.size(); i++) {
            BenefitsItem apiItem = benefitsItems[i];
            CoverageBenefitItem dbItem = insertedItems[i];
            
            if (apiItem.benefitsItemLimit != null && !apiItem.benefitsItemLimit.isEmpty()) {
                for (BenefitsItemLimit itemLimit : apiItem.benefitsItemLimit) {
                    CoverageBenefitItemLimit benefitLimit = new CoverageBenefitItemLimit();
                    benefitLimit.Name = itemLimit.benefitCode + ' - ' + itemLimit.coverageLevel;
                    benefitLimit.CoverageBenefitItemId = dbItem.Id;
                    benefitLimit.AllowedLimit = itemLimit.benefitValue;
                    benefitLimit.AppliedLimit = itemLimit.benefitValue;
                    benefitLimit.CoverageLevel = itemLimit.coverageLevel;
                    benefitLimit.LimitNotes = itemLimit.limitNotes;
                    benefitLimit.TermType = itemLimit.termType;
                    benefitLimit.PriorityOrder = 1;
                    
                    limitsToInsert.add(benefitLimit);
                }
            }
        }
        
        if (!limitsToInsert.isEmpty()) {
            insert limitsToInsert;
        }
    }
    
    /**
     * @description Parse date string to Date object
     */
    private static Date parseDate(String dateString) {
        if (String.isBlank(dateString)) {
            return null;
        }
        
        try {
            List<String> parts = dateString.split('/');
            if (parts.size() == 3) {
                Integer year = Integer.valueOf(parts[0]);
                Integer month = Integer.valueOf(parts[1]);
                Integer day = Integer.valueOf(parts[2]);
                return Date.newInstance(year, month, day);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to parse date: ' + dateString);
        }
        
        return null;
    }
} 