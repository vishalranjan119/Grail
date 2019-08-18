/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_CreateMilestoneController_Test
Class Purpose: Test class for OA_CreateMilestoneController
Versions: 1.1
******************************************************************************************************/

@isTest
public class OA_CreateMilestoneController_Test {
    
    @isTest
    public static void testCreateMilestoneController(){
        Account testAcc = OA_TestDataUtility.createAccount();
        insert testAcc;
        
        Opportunity testOpp = OA_TestDataUtility.createOpportunity(testAcc);
        testOpp.StageName = 'Proposal';
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
            Test.setCurrentPageReference(new PageReference('Page.OA_CreateMilestone')); 
            System.currentPageReference().getParameters().put('type', 'cr');
        System.currentPageReference().getParameters().put('pid', testOpp.id);
        System.currentPageReference().getParameters().put('crid', crOpp.id);
       
        ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        	OA_CreateMilestoneController cms = new  OA_CreateMilestoneController(sc);
        	
        	cms.createMilestones();
        	cms.deleteMilestone();
        	cms.enableEditing();
        	cms.loadMoreRows();
        	cms.togleEmptyRows();
        	cms.renderToOpp();
        	cms.rejectCR();
        	
        Test.stopTest();
        
    }
    
     @isTest
    public static void testCRClose(){
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
        
        Test.startTest();
        	ApexPages.StandardController sc = new ApexPages.StandardController(testOpp);
        	OA_CreateMilestoneController cms = new  OA_CreateMilestoneController(sc);
        	cms.createMilestones();
        	cms.deleteMilestone();
        	cms.enableEditing();
        	cms.loadMoreRows();
        	cms.togleEmptyRows();
        	cms.renderToOpp();
        	cms.getMilestoneWrapper();
        	
        Test.stopTest();
        
    }

}