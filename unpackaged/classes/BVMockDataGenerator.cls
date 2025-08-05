public class BVMockDataGenerator {  
    private static final String SEPARATOR = '~';

    public String getBenefitsItemKey(String memberNumber, String groupNumber) {
        return memberNumber;
    }
    
    public String getBenefitsItemLimitKey(String memberNumber, String groupNumber, String benefitsItemId) {
        return memberNumber + SEPARATOR + benefitsItemId;
    }
    
    public String getBenefitsItemLimitKey(String benefitsItemKey, String benefitsItemId) {
        return benefitsItemKey + SEPARATOR + benefitsItemId;
    }
    
    public String getHappyPathKey() {
        return '1234';
    }

    public String getErrorKey() {
        return '12345';
    }

    
    public Map<String, healthcloudext.BenefitsVerificationResponse> generateBVResponseMap() {
        System.debug('Inside generateBVResponseMap');
        List<String[]> benefitsResponseList = 
            new List<String[]> {
                                            // memberNumber, groupNumber, benefitsRequestId, isCoverageActive, BenefitPeriodStartDate, BenefitPeriodEndDate, errorResponse, jsonResponse
                                new String[] {'1234', 'crm123', '00005343', 'true', '2001/01/01', '2022/01/01', '', ''},
                                new String[] {'12345', 'crm123', '00005343', 'false', '', '', 'Invalid Member Number', ''},
                                new String[] {'234451', '54321', '98765', 'true', '2020/01/01', '2021/12/31', '', ''},
                                new String[] {'234452', '54322', '98766', 'true', '2020/04/01', '2021/06/30', '', ''},
                                new String[] {'234453', '54323', '98767', 'false', '2020/08/01', '2022/12/31', '', ''},
                                new String[] {'234454', '54324', '98768', 'true', '2020/12/01', '2022/06/30', '', ''},
                                new String[] {'234455', '54325', '98769', 'false', '2021/01/01', '2023/01/01', '', ''},
                                new String[] {'75656981', '65432', '87654', 'true', '2021/02/01', '2023/02/01', '', ''},
                                new String[] {'75656982', '65433', '87655', 'true', '2021/03/01', '2023/03/01', '', ''},
                                new String[] {'75656983', '65434', '87656', 'false', '2021/04/01', '2023/04/01', '', ''},
                                new String[] {'9765667', '76543', '76543', 'true', '2021/05/01', '2023/05/01', '', ''},
                                new String[] {'874565756', '87654', '65432', 'true', '2021/06/01', '2023/06/01', '', ''},
                                new String[] {'5689970', '98765', '54321', 'false', '2021/07/01', '2023/07/01', '', ''}
                            };
        Map<String, List<List<String>>> benefitsItemMap = 
            new Map<String, List<List<String>>> {
                '1234' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'additionnal info', 'true'},
                    new String[]{'2', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Out of Network additionnal info', 'false'},
                    new String[]{'3', 'Immunizations', '80', 'Immunizations', 'Flu Vaccine by Primary Care Physician', 'true'},
                    new String[]{'4', 'Urgent Care', 'UC', 'Urgent Care', 'Medical services and supplies provided by physicians or other healthcare providers for the treatment of an urgent medical condition or injury which requires medical attention.', 'true'},
                    new String[]{'5', 'Urgent Care', 'UC', 'Urgent Care', 'Out of Network - Medical services and supplies provided by physicians or other healthcare providers for the treatment of an urgent medical condition or injury which requires medical attention.', 'false'},
                    new String[]{'6', 'Emergency Services', '86', 'Emergency Services', 'Services provided by healthcare providers for the treatment of a sudden and unexpected medical condition or injury which requires immediate medical attention', 'false'}
                },
                '234451' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Standard health benefits coverage for member 234451', 'true'}                    
                },
                '234452' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Comprehensive health benefits for member 234452', 'true'}                    
                },
                '234453' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Basic health coverage for member 234453', 'false'}                    
                },
                '234454' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Premium health benefits for member 234454', 'true'}                    
                },
                '234455' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Limited health coverage for member 234455', 'false'}                    
                },
                '75656981' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Family health coverage for member 75656981', 'true'}                    
                },
                '75656982' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Individual health coverage for member 75656982', 'true'}                    
                },
                '75656983' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Basic coverage for member 75656983', 'false'}                    
                },
                '9765667' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Standard coverage for member 9765667', 'true'}                    
                },
                '874565756' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Comprehensive coverage for member 874565756', 'true'}                    
                },
                '5689970' => new List<List<String>> {
                                // benefitsItemId (unique number), serviceType, serviceTypeCode, benefitsCategory, notes, inPlanNetworkIndicator
                    new String[]{'1', 'Health Benefits Plan Coverage', '30', 'Plan Coverage and General Benefits', 'Limited coverage for member 5689970', 'false'}                    
                }
                
            };
        
        Map<String, List<List<String>>> benefitsItemLimitMap = 
            new Map<String, List<List<String>>> {
                '1234~1' => new List<List<String>> {
                                // benefitCode, benefitValue, benefitMetricType, coverageLevel, limitNotes, termType, networkType, Count
                    new String[]{'C', '2800', 'Money', 'Family', 'Information About Limit', 'Calendar Year', 'IN', '1'},
                    new String[]{'C', '1300', 'Money', 'Family', 'Information About Limit', 'Remaining', 'IN', '1'},
                    new String[]{'C', '1200', 'Money', 'Individual', 'Information About Limit', 'Calendar Year', 'IN', '1'},
                    new String[]{'C', '1050', 'Money', 'Individual', 'Information About Limit', 'Remaining', 'IN', '1'},
                    new String[]{'C', '5400', 'Money', 'Family', 'Information About Limit', 'Calendar Year', 'OUT', '1'},
                    new String[]{'C', '1140', 'Money', 'Family', 'Information About Limit', 'Remaining', 'OUT', '1'},
                    new String[]{'C', '1800', 'Money', 'Individual', 'Information About Limit', 'Calendar Year', 'OUT', '1'},
                    new String[]{'C', '1300', 'Money', 'Individual', 'Information About Limit', 'Remaining', 'OUT', '1'},
                    new String[]{'C', '1300', 'Money', 'Individual', 'Information About Limit', 'Remaining', 'OUT', '1'},
                    new String[]{'B', '25', 'Money', 'Individual', 'Co-Payment', 'Day', 'IN', '1'},
                    new String[]{'B', '25', 'Money', 'Family', 'Co-Payment', 'Day', 'IN', '1'},
                    new String[]{'B', '50', 'Money', 'Individual', 'Co-Payment', 'Day', 'OUT', '1'},
                    new String[]{'B', '50', 'Money', 'Family', 'Co-Payment', 'Day', 'OUT', '1'},
                    // out of pocket
                    new String[]{'G', '3000', 'Money', 'Family', 'All Other In-Network Providers', 'Calendar Year', 'IN', '1'},
                    new String[]{'G', '1200', 'Money', 'Family', 'All Other In-Network Providers', 'Remaining', 'IN', '1'},
                    new String[]{'G', '8000', 'Money', 'Family', 'All Other In-Network Providers', 'Calendar Year', 'OUT', '1'},
                    new String[]{'G', '3500', 'Money', 'Family', 'All Other In-Network Providers', 'Remaining', 'OUT', '1'},
                    new String[]{'G', '300', 'Money', 'Individual', 'All Other In-Network Providers', 'Calendar Year', 'IN', '1'},
                    new String[]{'G', '120', 'Money', 'Individual', 'All Other In-Network Providers', 'Remaining', 'IN', '1'},
                    new String[]{'G', '800', 'Money', 'Individual', 'All Other In-Network Providers', 'Calendar Year', 'OUT', '1'},
                    new String[]{'G', '350', 'Money', 'Individual', 'All Other In-Network Providers', 'Remaining', 'OUT', '1'},
                    new String[]{'A', '20', 'Percentage', 'Family', 'Flu Vaccine in Office', 'Calendar Year', 'IN', '1'},
                    new String[]{'A', '35', 'Percentage', 'Family', 'Flu Vaccine in Office', 'Remaining', 'OUT', '1'}
                },
                '1234~2' => new List<List<String>> {
                    new String[]{'C', '2400', 'Money', 'Family', 'Information About Limit', 'Calendar Year', 'OUT', '1'}
                },
                '1234~3' => new List<List<String>> {
                    new String[]{'B', '0', 'Money', 'Individual', 'Flu Vaccine by Primary Care Physician', 'Day', 'IN', '1'}
                },
                '1234~4' => new List<List<String>> {
                    new String[]{'B', '25', 'Money', 'Individual', 'Urgent Care - In Network', 'Day', 'IN', '1'}
                },
                '1234~5' => new List<List<String>> {
                    new String[]{'B', '100', 'Money', 'Individual', 'Urgent Care - Out Network', 'Day', 'OUT', '1'}
                },
                '1234~6' => new List<List<String>> {
                    new String[]{'B', '500', 'Money', 'Individual', 'Emergency Care', 'Day', 'OUT', '1'}
                },
                '234451~1' => new List<List<String>> {
                    new String[]{'C', '2500', 'Money', 'Family', 'Annual deductible for family coverage', 'Calendar Year', 'IN', '1'},
                    new String[]{'B', '30', 'Money', 'Individual', 'Co-payment for office visits', 'Day', 'IN', '1'},
                    new String[]{'G', '4000', 'Money', 'Family', 'Out-of-pocket maximum', 'Calendar Year', 'IN', '1'}
                },
                '234452~1' => new List<List<String>> {
                    new String[]{'C', '2000', 'Money', 'Individual', 'Annual deductible for individual', 'Calendar Year', 'IN', '1'},
                    new String[]{'B', '25', 'Money', 'Individual', 'Co-payment for specialist visits', 'Day', 'IN', '1'},
                    new String[]{'G', '3000', 'Money', 'Individual', 'Out-of-pocket maximum', 'Calendar Year', 'IN', '1'}
                },
                '234453~1' => new List<List<String>> {
                    new String[]{'C', '1500', 'Money', 'Individual', 'Basic deductible', 'Calendar Year', 'OUT', '1'},
                    new String[]{'B', '50', 'Money', 'Individual', 'Higher co-payment for out-of-network', 'Day', 'OUT', '1'},
                    new String[]{'G', '6000', 'Money', 'Individual', 'Higher out-of-pocket maximum', 'Calendar Year', 'OUT', '1'}
                },
                '234454~1' => new List<List<String>> {
                    new String[]{'C', '3000', 'Money', 'Family', 'Premium family deductible', 'Calendar Year', 'IN', '1'},
                    new String[]{'B', '20', 'Money', 'Individual', 'Low co-payment for premium plan', 'Day', 'IN', '1'},
                    new String[]{'G', '2500', 'Money', 'Family', 'Low out-of-pocket maximum', 'Calendar Year', 'IN', '1'}
                },
                '234455~1' => new List<List<String>> {
                    new String[]{'C', '1000', 'Money', 'Individual', 'Limited coverage deductible', 'Calendar Year', 'OUT', '1'},
                    new String[]{'B', '75', 'Money', 'Individual', 'High co-payment for limited plan', 'Day', 'OUT', '1'},
                    new String[]{'G', '8000', 'Money', 'Individual', 'High out-of-pocket maximum', 'Calendar Year', 'OUT', '1'}
                },
                '75656981~1' => new List<List<String>> {
                    new String[]{'C', '2800', 'Money', 'Family', 'Family plan deductible', 'Calendar Year', 'IN', '1'},
                    new String[]{'B', '35', 'Money', 'Individual', 'Family plan co-payment', 'Day', 'IN', '1'},
                    new String[]{'G', '3500', 'Money', 'Family', 'Family out-of-pocket maximum', 'Calendar Year', 'IN', '1'}
                },
                '75656982~1' => new List<List<String>> {
                    new String[]{'C', '1800', 'Money', 'Individual', 'Individual plan deductible', 'Calendar Year', 'IN', '1'},
                    new String[]{'B', '30', 'Money', 'Individual', 'Individual plan co-payment', 'Day', 'IN', '1'},
                    new String[]{'G', '2800', 'Money', 'Individual', 'Individual out-of-pocket maximum', 'Calendar Year', 'IN', '1'}
                },
                '75656983~1' => new List<List<String>> {
                    new String[]{'C', '1200', 'Money', 'Individual', 'Basic individual deductible', 'Calendar Year', 'OUT', '1'},
                    new String[]{'B', '60', 'Money', 'Individual', 'Basic plan co-payment', 'Day', 'OUT', '1'},
                    new String[]{'G', '5000', 'Money', 'Individual', 'Basic out-of-pocket maximum', 'Calendar Year', 'OUT', '1'}
                },
                '9765667~1' => new List<List<String>> {
                    new String[]{'C', '2200', 'Money', 'Family', 'Standard family deductible', 'Calendar Year', 'IN', '1'},
                    new String[]{'B', '40', 'Money', 'Individual', 'Standard co-payment', 'Day', 'IN', '1'},
                    new String[]{'G', '3200', 'Money', 'Family', 'Standard out-of-pocket maximum', 'Calendar Year', 'IN', '1'}
                },
                '874565756~1' => new List<List<String>> {
                    new String[]{'C', '3500', 'Money', 'Family', 'Comprehensive family deductible', 'Calendar Year', 'IN', '1'},
                    new String[]{'B', '15', 'Money', 'Individual', 'Comprehensive plan co-payment', 'Day', 'IN', '1'},
                    new String[]{'G', '2000', 'Money', 'Family', 'Comprehensive out-of-pocket maximum', 'Calendar Year', 'IN', '1'}
                },
                '5689970~1' => new List<List<String>> {
                    new String[]{'C', '800', 'Money', 'Individual', 'Limited individual deductible', 'Calendar Year', 'OUT', '1'},
                    new String[]{'B', '80', 'Money', 'Individual', 'Limited plan co-payment', 'Day', 'OUT', '1'},
                    new String[]{'G', '9000', 'Money', 'Individual', 'Limited out-of-pocket maximum', 'Calendar Year', 'OUT', '1'}
                }
            }; 
        
        Map<String, healthcloudext.BenefitsVerificationResponse> benefitsVerificationResponseMap = new Map<String, healthcloudext.BenefitsVerificationResponse>();
        
        for (String[] values : benefitsResponseList) {
            String key = getBenefitsItemKey(values[0], values[1]);
                        
            List<List<String>> bis = benefitsItemMap.get(key);
            
            List<healthcloudext.BenefitsItem> biList = new List<healthcloudext.BenefitsItem>();
            
            if (bis != null) {
                
                for (String[] biArray : bis) {
                    String biKey = getBenefitsItemLimitKey(key, biArray[0]);                    
                
                    List<healthcloudext.BenefitsItemLimit> bilList = new List<healthcloudext.BenefitsItemLimit>();
                    
                    List<List<String>> bils = benefitsItemLimitMap.get(biKey);
                    
                    if (bils != null) {
                        for (String[] bilArray : bils) {
                            Integer cnt = Integer.valueOf(bilArray[7]);
                            for (Integer i = 0; i < cnt; i++) {
                                bilList.add(getBenefitsItemLimit(bilArray[0], bilArray[1], bilArray[2], bilArray[3], bilArray[4], bilArray[5], bilArray[6], i+1));
                            }
                        }
                    }
                
                    healthcloudext.BenefitsItem bi = getBenefitsItem(biArray[1], biArray[2], biArray[3], biArray[4], biArray[5], bilList);
                
                    biList.add(bi);
                }
            }
            
            healthcloudext.BenefitsVerificationResponse bvr = getBenefitsVerificationResponse(values[0], values[1], values[2], values[3], values[4], values[5], biList, values[6], values[7]);    

            benefitsVerificationResponseMap.put(key, bvr);
        }
        
        return benefitsVerificationResponseMap;
    }
    
    public void debugBenefitsVerificationResponse(healthcloudext.BenefitsVerificationResponse response) {
        System.debug('BenefitsVerificationResponse{memberNumber=' + response.memberNumber + ';groupNumber=' + response.groupNumber + ';benefitsRequestId=' + response.benefitsRequestId +
                                                        ';isCoverageActive=' + response.isCoverageActive + ';benefitPeriodStartDate=' + response.benefitPeriodStartDate +
                                                        ';benefitPeriodEndDate=' + response.benefitPeriodEndDate + ';errorResponse=' + response.errorResponse + 
                                                        ';jsonResponse' + response.jsonResponse);
        
        if (response.benefitsItem != null) {
            for (healthcloudext.BenefitsItem bi : response.benefitsItem) {
                debugBenefitsItem(bi);
            }
        }
    }
    
    public void debugBenefitsItem(healthcloudext.BenefitsItem bi) {
        System.debug('=>BenefitsItem{serviceType=' + bi.serviceType + ';serviceTypeCode=' + bi.serviceTypeCode + 
                                    ';benefitsCategory=' + bi.benefitsCategory + ';notes=' + bi.notes + 
                                    ';inPlanNetworkIndicator=' + bi.inPlanNetworkIndicator);
        if (bi.benefitsItemLimit != null) {
            for (healthcloudext.BenefitsItemLimit bil : bi.benefitsItemLimit) {
                debugBenefitsItemLimit(bil);
            }
        }
    }
    
    public void debugBenefitsItemLimit(healthcloudext.BenefitsItemLimit bil) {
        System.debug('==>BenefitsItemLimit{benefitCode=' + bil.benefitCode + ';benefitValue=' + bil.benefitValue + ';benefitMetricType=' + bil.benefitMetricType + 
                                        ';coverageLevel=' + bil.coverageLevel + ';limitNotes=' + bil.limitNotes + ';termType=' + bil.termType + 
                                        ';networkType=' + bil.networkType);
    }
    
    private healthcloudext.BenefitsVerificationResponse getBenefitsVerificationResponse(
                                            String memberNumber, String groupNumber, String benefitsRequestId, 
                                            String isCoverageActive, String benefitPeriodStartDate, 
                                            String benefitPeriodEndDate, List<healthcloudext.BenefitsItem> benefitsItem,
                                            String errorResponse, String jsonResponse) {
        System.debug('Inside getBenefitsVerificationResponse');
        healthcloudext.BenefitsVerificationResponse bvr = new healthcloudext.BenefitsVerificationResponse();
        
        bvr.memberNumber = memberNumber;
        bvr.groupNumber = groupNumber;
        bvr.benefitsRequestId = benefitsRequestId;
        bvr.isCoverageActive = Boolean.valueOf(isCoverageActive);
        bvr.benefitPeriodStartDate = benefitPeriodStartDate;
        bvr.benefitPeriodEndDate = benefitPeriodEndDate;
        bvr.benefitsItem = benefitsItem;
        bvr.errorResponse = errorResponse;
        bvr.jsonResponse = jsonResponse;
        
        return bvr;
    }
    
    private healthcloudext.BenefitsItem getBenefitsItem(String serviceType, String serviceTypeCode, String benefitsCategory, 
                                                        String notes, String inPlanNetworkIndicator,
                                                       List<healthcloudext.BenefitsItemLimit> benefitsItemLimit) {
        System.debug('Inside getBenefitsItem');
        healthcloudext.BenefitsItem bi = new healthcloudext.BenefitsItem();
            
        bi.serviceType = serviceType;
        bi.serviceTypeCode = serviceTypeCode;
        bi.benefitsCategory = benefitsCategory;
        bi.notes = notes;
        bi.inPlanNetworkIndicator = Boolean.valueOf(inPlanNetworkIndicator);
        bi.benefitsItemLimit = benefitsItemLimit;
                                                           
        return bi;
    }
    
    private healthcloudext.BenefitsItemLimit getBenefitsItemLimit(
                                            String benefitCode, String benefitValue, String benefitMetricType, 
                                            String coverageLevel, String limitNotes, String termType, 
                                            String networkType, Integer index) {
        System.debug('Inside getBenefitsItemLimit');
        healthcloudext.BenefitsItemLimit bil = new healthcloudext.BenefitsItemLimit();
            
        bil.benefitCode = benefitCode;
        bil.benefitValue = benefitValue;
        bil.benefitMetricType = benefitMetricType;
        bil.coverageLevel = coverageLevel;
        bil.limitNotes = limitNotes;
        bil.termType = termType;
        bil.networkType = networkType;
        
        return bil;
    }
}