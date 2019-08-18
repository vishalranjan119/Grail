@isTest
public class OA_Utility_Test {
    
    @isTest
    public static void testUtility(){
        
        OA_Utility.getMonthMap();
        OA_Utility.getRecordTypeInfosByName('Opportunity');
        OA_Utility.handleDeleteResult();
        OA_Utility.handleSaveResult();
        OA_Utility.handleUpsertResult(new List<Database.UpsertResult>());
        OA_Utility.addMessage('', 'NONE');
        
        
    }

}