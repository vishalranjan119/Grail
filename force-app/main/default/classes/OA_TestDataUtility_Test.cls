@isTest
public class OA_TestDataUtility_Test {
    
    @isTest
    public static void testDataUtility(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        
        Opportunity o = OA_TestDataUtility.createOpportunity(a);
        insert o;
        
        Contact c = OA_TestDataUtility.createContact(a);
        insert c;
        
        OA_TestDataUtility.createEvent(a);
        OA_TestDataUtility.createRevForecast(o);
        
        Sales_Quota__c sq = OA_TestDataUtility.createCSOSalesQuota();
        insert sq;
        
        OA_TestDataUtility.createMonthlyQuota(sq);
        
        OA_TestDataUtility.createRegionalSalesQuota();
        OA_TestDataUtility.createAccountSalesQuota(a);
        
        
    }

}