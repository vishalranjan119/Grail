/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_ConLastActivityEventBatchTest
Class Purpose: Unit test class for OA_ContactLastActivityUpdateEvent_Batch
Versions: 1.1
******************************************************************************************************/
@isTest
public Class OA_ConLastActivityEventBatchTest{
    @isTest static void testExecute(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        Contact c = OA_TestDataUtility.createContact(a);
        insert c;
        Event e = OA_TestDataUtility.createEvent(a);
        e.WhoId = c.id;
        insert e;
        Test.startTest();
            Contact co = [SELECT id, Last_Activity__c FROM Contact];
            System.Assert(co.Last_Activity__c==null);
            OA_ContactLastActivityUpdateEvent_Batch abc = new OA_ContactLastActivityUpdateEvent_Batch();
            Database.executeBatch(abc);
            String sch = '0 0 23 * * ?';
            System.schedule('Test Scheduler', sch, abc); 
        Test.stopTest();
        Contact con = [SELECT id, Last_Activity__c FROM Contact];
        //System.Assert(con.Last_Activity__c!=null);
    }
}