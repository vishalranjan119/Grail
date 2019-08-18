/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_DisplayMilestoneController_Test
Class Purpose: Test class for OA_DisplayMilestoneController
Versions: 1.1
******************************************************************************************************/

@isTest
public class OA_DisplayMilestoneController_Test {
     @isTest
    public static void testDisplayMilestoneController(){
        Account testAcc = OA_TestDataUtility.createAccount();
        insert testAcc;
        
        Opportunity testOpp = OA_TestDataUtility.createOpportunity(testAcc);
        testOpp.StageName = 'Proposed';
        insert testOpp;
        
        Opportunity crOpp = OA_TestDataUtility.createOpportunity(testAcc);
        crOpp.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName = 'Change_Request'].Id;
        crOpp.StageName = 'Proposed';
        crOpp.OA_Parent_Project__c = testOpp.Id;
        insert crOpp;
        
        List<OA_Revenue_Forecast__c> testRFCR = OA_TestDataUtility.createRevForecast(crOpp);
        insert testRFCR;
        
        List<OA_Revenue_Forecast__c> testRF = OA_TestDataUtility.createRevForecast(testOpp);
        insert testRF;
        
        Test.startTest();
        	ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        	OA_DisplayMilestoneController dmc = new OA_DisplayMilestoneController(sc);
        Test.stopTest();
    }

}