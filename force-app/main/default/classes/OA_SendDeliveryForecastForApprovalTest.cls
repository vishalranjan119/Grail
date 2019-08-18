/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_SendDeliveryForecastForApprovalTest
Class Purpose: Test class for OA_SendDeliveryForecastForApproval_Batch
Versions: 1.1
******************************************************************************************************/
@isTest
public class OA_SendDeliveryForecastForApprovalTest{
    @isTest static void testExecute(){
        Account testAcc = OA_TestDataUtility.createAccount();
        insert testAcc;
        
        Opportunity testOpp = OA_TestDataUtility.createOpportunity(testAcc);
        testOpp.StageName = 'Proposal';
        insert testOpp;
        
        List<OA_Revenue_Forecast__c> testRF = OA_TestDataUtility.createRevForecast(testOpp);
        for(OA_Revenue_Forecast__c o : testRF){
            o.OA_Status__c = 'Planned';
            o.OA_Month__c = String.valueOf(System.Today().Month());
            o.OA_Year__c = String.valueOf(System.today().year());
        }
        insert testRF;
        testOpp.StageName='Closed Won' ;
        testOpp.OA_Rate_Card_Price__c = 2000;
        Update testOpp;
        /*Opportunity crOpp = OA_TestDataUtility.createOpportunity(testAcc);
        crOpp.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName = 'Change_Request'].Id;
        crOpp.StageName = 'Closed Won';
        crOpp.OA_Parent_Project__c = testOpp.Id;
        insert crOpp;
        
        List<OA_Revenue_Forecast__c> testRFCR = OA_TestDataUtility.createRevForecast(crOpp);
        insert testRFCR;*/
        
        Sales_Quota__c sc = OA_TestDataUtility.createRegionalSalesQuota();
        insert sc;
        
        OA_Monthly_Quota__c mq = OA_TestDataUtility.createMonthlyQuota(sc);
        insert mq; 
        
        Test.startTest();
            OA_SendDeliveryForecastForApproval_Batch abc = new OA_SendDeliveryForecastForApproval_Batch();
            Database.executeBatch(abc);
            String sch = '0 0 23 * * ?';
            //system.schedule('Test Scheduler Code', sch, abc); 
        Test.stopTest();
    }    
}