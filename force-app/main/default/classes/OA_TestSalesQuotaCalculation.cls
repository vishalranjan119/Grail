@isTest
public class OA_TestSalesQuotaCalculation {
    
    @isTest
    public static void testSOLDCalculation(){
        Account acc = OA_TestDataUtility.createAccount();
        insert acc;
        
        Opportunity opp = OA_TestDataUtility.createOpportunity(acc);
        insert opp;
        
        List<OA_Revenue_Forecast__c> rfList = OA_TestDataUtility.createRevForecast(opp);
        insert rfList;
        
        Sales_Quota__c sq = OA_TestDataUtility.createCSOSalesQuota();
        insert sq;
        Sales_Quota__c accsq = OA_TestDataUtility.createAccountSalesQuota(acc);
        insert accsq;
        Sales_Quota__c regsq = OA_TestDataUtility.createRegionalSalesQuota();
        insert regsq;
        
        OA_Monthly_Quota__c mq1 = OA_TestDataUtility.createMonthlyQuota(sq);
        insert mq1;
        
        OA_Monthly_Quota__c mq2= OA_TestDataUtility.createMonthlyQuota(accsq);
        insert mq2;
        
        OA_Monthly_Quota__c mq3 = OA_TestDataUtility.createMonthlyQuota(regsq);
        insert mq3;
        
        OA_SalesQuotaCalculation cal = new OA_SalesQuotaCalculation();
        Database.executeBatch(cal);
    }
    
    @isTest
    public static void testPipelineCalculation(){
        Account acc = OA_TestDataUtility.createAccount();
        insert acc;
        
        Opportunity opp = OA_TestDataUtility.createOpportunity(acc);
        opp.StageName = 'Proposed';
        insert opp;
        
        List<OA_Revenue_Forecast__c> rfList = OA_TestDataUtility.createRevForecast(opp);
        insert rfList;
        
        Sales_Quota__c sq = OA_TestDataUtility.createCSOSalesQuota();
        insert sq;
        Sales_Quota__c accsq = OA_TestDataUtility.createAccountSalesQuota(acc);
        insert accsq;
        Sales_Quota__c regsq = OA_TestDataUtility.createRegionalSalesQuota();
        insert regsq;
        
        OA_Monthly_Quota__c mq1 = OA_TestDataUtility.createMonthlyQuota(sq);
        insert mq1;
        
        OA_Monthly_Quota__c mq2= OA_TestDataUtility.createMonthlyQuota(accsq);
        insert mq2;
        
        OA_Monthly_Quota__c mq3 = OA_TestDataUtility.createMonthlyQuota(regsq);
        insert mq3;
        
        OA_SalesQuotaCalculation cal = new OA_SalesQuotaCalculation();
        Database.executeBatch(cal);
    }
    
    
    
}