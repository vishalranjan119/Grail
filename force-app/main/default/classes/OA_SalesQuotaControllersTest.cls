/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_SalesQuotaControllersTest
Class Purpose: Unit test class for Testing the Sales Quota Screen Controllers
Versions: 1.1
******************************************************************************************************/
@isTest
public class OA_SalesQuotaControllersTest{
    @isTest
    public static void testRegionQuota(){
        Account testAcc = OA_TestDataUtility.createAccount();
        insert testAcc;
        
        Opportunity testOpp = OA_TestDataUtility.createOpportunity(testAcc);
        testOpp.StageName = 'Proposed';
        insert testOpp;
        
        List<OA_Revenue_Forecast__c> testRF = OA_TestDataUtility.createRevForecast(testOpp);
        insert testRF;
        
        Opportunity crOpp = OA_TestDataUtility.createOpportunity(testAcc);
        crOpp.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName = 'Change_Request'].Id;
        crOpp.StageName = 'Proposed';
        crOpp.OA_Parent_Project__c = testOpp.Id;
        insert crOpp;
        
        List<OA_Revenue_Forecast__c> testRFCR = OA_TestDataUtility.createRevForecast(crOpp);
        insert testRFCR;
        
        Sales_Quota__c sc = OA_TestDataUtility.createRegionalSalesQuota();
        insert sc;
        
        OA_Monthly_Quota__c mq = OA_TestDataUtility.createMonthlyQuota(sc);
        insert mq; 
        
        Test.startTest();
            Test.setCurrentPageReference(new PageReference('Page.OA_RegionalSalesQuota')); 
            System.currentPageReference().getParameters().put('id', sc.id);
            ApexPages.StandardController sCon = new ApexPages.StandardController(sc);
            OA_RegionalSalesQuotaController rsq = new  OA_RegionalSalesQuotaController(sCon);
            rsq.save();
            rsq.cancel();
            rsq.getAllCalculations();
        Test.stopTest();    
    }
    @isTest
    public static void testAgentQuota(){
        Account testAcc = OA_TestDataUtility.createAccount();
        insert testAcc;
        
        Opportunity testOpp = OA_TestDataUtility.createOpportunity(testAcc);
        testOpp.StageName = 'Proposed';
        insert testOpp;
        
        List<OA_Revenue_Forecast__c> testRF = OA_TestDataUtility.createRevForecast(testOpp);
        insert testRF;
        
        Opportunity crOpp = OA_TestDataUtility.createOpportunity(testAcc);
        crOpp.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName = 'Change_Request'].Id;
        crOpp.StageName = 'Proposed';
        crOpp.OA_Parent_Project__c = testOpp.Id;
        insert crOpp;
        
        List<OA_Revenue_Forecast__c> testRFCR = OA_TestDataUtility.createRevForecast(crOpp);
        insert testRFCR;
        
        Sales_Quota__c scR = OA_TestDataUtility.createRegionalSalesQuota();
        insert scR;
        
        Sales_Quota__c sc = OA_TestDataUtility.createCSOSalesQuota();
        insert sc;
        
        OA_Monthly_Quota__c mq = OA_TestDataUtility.createMonthlyQuota(sc);
        insert mq; 
        
        Test.startTest();
            Test.setCurrentPageReference(new PageReference('Page.OA_AgentSalesQuota')); 
            System.currentPageReference().getParameters().put('id', sc.id);
            ApexPages.StandardController sCon = new ApexPages.StandardController(sc);
            OA_AgentSalesQuotaController rsq = new  OA_AgentSalesQuotaController(sCon);
            rsq.yearSelected = '2019';
            
            rsq.save();
            rsq.cancel();
        Test.stopTest();    
    }
    @isTest
    public static void testAccountQuota(){
        Account testAcc = OA_TestDataUtility.createAccount();
        insert testAcc;
        
        Opportunity testOpp = OA_TestDataUtility.createOpportunity(testAcc);
        testOpp.StageName = 'Proposed';
        insert testOpp;
        
        List<OA_Revenue_Forecast__c> testRF = OA_TestDataUtility.createRevForecast(testOpp);
        insert testRF;
        
        Opportunity crOpp = OA_TestDataUtility.createOpportunity(testAcc);
        crOpp.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName = 'Change_Request'].Id;
        crOpp.StageName = 'Proposed';
        crOpp.OA_Parent_Project__c = testOpp.Id;
        insert crOpp;
        
        List<OA_Revenue_Forecast__c> testRFCR = OA_TestDataUtility.createRevForecast(crOpp);
        insert testRFCR;
        
        Sales_Quota__c scA = OA_TestDataUtility.createCSOSalesQuota();
        insert scA;
        
        Sales_Quota__c sc = OA_TestDataUtility.createAccountSalesQuota(testAcc);
        insert sc;
        
        OA_Monthly_Quota__c mq = OA_TestDataUtility.createMonthlyQuota(sc);
        insert mq; 
        
        Test.startTest();
            Test.setCurrentPageReference(new PageReference('Page.OA_AccountSalesQuota')); 
            System.currentPageReference().getParameters().put('id', sc.id);
            ApexPages.StandardController sCon = new ApexPages.StandardController(sc);
            OA_AccountSalesQuotaController rsq = new  OA_AccountSalesQuotaController(sCon);
            rsq.save();
            rsq.cancel();
        Test.stopTest();    
    }
}