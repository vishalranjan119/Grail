@isTest
public class OA_BR_SalesGoalViewCntrl_Test {
    public static testMethod void validateReport(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
          OA_Budget__c sq = OA_TestDataUtility.createBudget();
        insert sq;
         OA_Monthly_Budget__c mq= OA_TestDataUtility.createMonthlyBudget(sq);
    insert mq;
        List<OA_Data_Snapshots__c> dataSnapList = new List<OA_Data_Snapshots__c>();
        OA_Data_Snapshots__c d = OA_TestDataUtility.createDataSnapShots();
        
        OA_Data_Snapshots__c d1 = OA_TestDataUtility.createDataSnapShots();
        d1.OA_Probability__c = 100;
        
        OA_Data_Snapshots__c d2 = OA_TestDataUtility.createDataSnapShots();
        
        d2.OA_Region__c = '';
        
        
        dataSnapList.add(d);
        dataSnapList.add(d1);
        dataSnapList.add(d2);
        
        insert dataSnapList;
        Test.startTest();
        OA_BR_SalesGoalViewCntrl cont = new OA_BR_SalesGoalViewCntrl();
            cont.selectedMonth = String.valueOf(Date.today().month());        
            cont.selectedYear = String.valueOf(date.today().year());
            cont.search();
        OA_BR_SalesGoalViewCntrl contt = new OA_BR_SalesGoalViewCntrl();
            contt.selectedMonth = String.valueOf(Date.today().month());        
            contt.selectedYear = String.valueOf(date.today().year()-1);
            contt.search();
        Test.stopTest();
    }
}