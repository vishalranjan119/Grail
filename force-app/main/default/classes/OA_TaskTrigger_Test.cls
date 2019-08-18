@isTest
public class OA_TaskTrigger_Test {
    
	@isTest
    public static void testTaskTrigger(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        Contact c = OA_TestDataUtility.createContact(a);
        insert c;
        
        Task t = new Task();
        t.WhoId = c.id;
        t.WhatId=a.id;
        t.Subject = 'Test';
        //t. =system.today()+5;
        insert t;
        
        Test.startTest();
        t.Status = 'Completed';
        update t;
        test.stopTest();
        
            
    }

}