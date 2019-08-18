@isTest
public class OA_TestOpportunitySplitTrigger {
    @isTest
    public static void testOpportunitySplitTrigger(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        Opportunity opp = OA_TestDataUtility.createOpportunity(a);
        insert opp;
        
    }
}