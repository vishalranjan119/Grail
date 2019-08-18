/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_AccountActivityOverdueCheck_BatchTest 
Class Purpose: Unit test class for OA_AccountActivityOverdueCheck_Batch
Versions: 1.1
******************************************************************************************************/
@isTest
public class OA_AccountActivityOverdueCheck_BatchTest {
    @isTest static void testExecute(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        Test.startTest();
            OA_Constant oa = new OA_Constant();
            OA_AccountActivityOverdueCheck_Batch abc = new OA_AccountActivityOverdueCheck_Batch();
            Database.executeBatch(abc);
            String sch = '0 0 23 * * ?';
            system.schedule('Test Scheduler Code', sch, abc); 
        Test.stopTest();
    }    
}