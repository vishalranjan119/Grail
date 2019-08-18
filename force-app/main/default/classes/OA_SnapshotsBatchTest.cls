/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_SnapshotsBatchTest
Class Purpose: Test class for OA_SnapshotsBatch
Versions: 1.1
******************************************************************************************************/
@isTest
public class OA_SnapshotsBatchTest {
	@isTest
    public static void testBatch(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        
        Opportunity o = OA_TestDataUtility.createOpportunity(a);
        o.StageName = 'Proposal';
        insert o;
        
        List<OA_Revenue_Forecast__c> rfList = OA_TestDataUtility.createRevForecast(o);
        insert rfList;  
        
        Test.startTest();
            OA_SnapshotsBatch batchTest = new OA_SnapshotsBatch();
            Database.executeBatch(batchTest);
            //String sch = '0 0 23 * * ?';
            //System.schedule('Testing snapshots Batch', sch, batchTest); 
        Test.stopTest();
        
    }
    
    @isTest
    public static void testBatchScheduler(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        
        Opportunity o = OA_TestDataUtility.createOpportunity(a);
        o.StageName = 'Proposal';
        insert o;
        
        List<OA_Revenue_Forecast__c> rfList = OA_TestDataUtility.createRevForecast(o);
        insert rfList;  
        
        Test.startTest();
            OA_SnapshotsBatch batchTest = new OA_SnapshotsBatch();
            //Database.executeBatch(batchTest);
            String sch = '0 0 23 * * ?';
            System.schedule('Testing snapshots Batch', sch, batchTest); 
        Test.stopTest();
        
    }  
}