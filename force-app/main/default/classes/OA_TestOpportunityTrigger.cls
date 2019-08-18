@isTest
public class OA_TestOpportunityTrigger {
    
    @testSetUp
    public static void insertTestData(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        
        Opportunity o = OA_TestDataUtility.createOpportunity(a);
        o.StageName = 'Proposal';
        insert o;
        
        Opportunity cr = OA_TestDataUtility.createOpportunity(a);
        cr.StageName = 'Proposal';
        cr.RecordTypeId = [SELECT id FROM RecordType WHERE Name = 'Change Request'].Id;
        cr.OA_Parent_Project__c = o.Id;
        insert cr;
        
        List<OA_Revenue_Forecast__c> rfList = OA_TestDataUtility.createRevForecast(o);
        insert rfList;
        
        List<OA_Revenue_Forecast__c> crRFList = OA_TestDataUtility.createRevForecast(cr);
        insert crRFList;
    }
    
    @isTest
    public static void testProjectClosedWon(){
        Opportunity o = [Select Id, StageName FROM Opportunity WHERE RecordType.DeveloperName = 'Project' LIMIT 1];
        Test.startTest();
        o.StageName =  'Closed Won';
        boolean isError = false;
        try{
            update o;
        }Catch(Exception e){
            isError = true;
        }
        System.assert(isError);
        Test.stopTest();
    }
    
     @isTest
    public static void testInvoiceCalculation(){
        Opportunity o = [Select Id, StageName FROM Opportunity WHERE RecordType.DeveloperName = 'Project' LIMIT 1];
        Test.startTest();
        o.Amount =  1000;
        update o;
        Test.stopTest();
    }
    
    @isTest
    public static void testCRClosedWon(){
        Opportunity o = [Select Id, StageName FROM Opportunity WHERE RecordType.DeveloperName = 'Change_Request' LIMIT 1];
        Test.startTest();
        o.StageName =  'Closed Won';       
        update o;
        Test.stopTest();
        
        o.Name = 'Change Name';
        boolean isError = false;
        try{
            update o;
        }Catch(Exception e){
            isError = true;
        }
        
        //System.assert(isError);
        
        isError = false;
        try{
            delete o;
        }Catch(Exception e){
            isError = true;
        }
        
        //System.assert(isError);
        
    }

}