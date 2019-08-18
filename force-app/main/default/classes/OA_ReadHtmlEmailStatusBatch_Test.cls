/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_ReadHtmlEmailStatusBatch_Test
Class Purpose: Unit test class for OA_ReadHtmlEmailStatusContactsBatch 
Versions: 1.1
******************************************************************************************************/
@isTest(SeeAllData=true)
/*used SeeAllData=True since EMAILSTATUS is an object which cannot be traversed directly in a test class. 
    For more details kindly refer: https://help.salesforce.com/articleView?id=000247964&language=en_US&type=1
*/
public Class OA_ReadHtmlEmailStatusBatch_Test{
    @isTest static Void testExecute(){ 
        Test.startTest();
            OA_ReadHtmlEmailStatusContactsBatch eventTest = new OA_ReadHtmlEmailStatusContactsBatch();
            Database.executeBatch(eventTest);
            String sch = '0 0 23 * * ?';
            System.schedule('Testing Events Batch', sch, eventTest); 
            OA_ReadHtmlEmailStatusLeadsBatch leadTest = new OA_ReadHtmlEmailStatusLeadsBatch();
            Database.executeBatch(leadTest);
            String sch1 = '0 0 23 * * ?';
            System.schedule('Testing Leads Batch', sch1, leadTest);
        Test.stopTest();
    }    
}