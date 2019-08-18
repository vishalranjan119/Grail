@isTest
public class OA_TestChangeRequest {
    
    @isTest
    public static void testChangeRequest(){
        
        Account testAcc = OA_TestDataUtility.createAccount();
        insert testAcc;
        
        Opportunity testOpp = OA_TestDataUtility.createOpportunity(testAcc);
        insert testOpp;
        List<OA_Revenue_Forecast__c> testRF = OA_TestDataUtility.createRevForecast(testOpp);
        insert testRF;
        testOpp.StageName='Closed Won' ;
        testOpp.OA_Rate_Card_Price__c = 2000;
        Update testOpp;
        Opportunity crOpp = OA_TestDataUtility.createOpportunity(testAcc);
        crOpp.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName = 'Change_Request'].Id;
        crOpp.StageName = 'Proposed';
        crOpp.OA_Parent_Project__c = testOpp.Id;
        insert crOpp;
        
        List<OA_Revenue_Forecast__c> testRFCR = OA_TestDataUtility.createRevForecast(crOpp);
        insert testRFCR;
        
        Test.startTest();
        	ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        	OA_ChangeRequestController cms = new  OA_ChangeRequestController(sc);
        	cms.initCROpp();
        	cms.createChangeRequest();
        	cms.getAdditionalRows();
        	cms.loadMoreRows();
        	cms.togleEmptyRows();
        	cms.renderToOpp();
        

        	
        Test.stopTest();
        
    }

}