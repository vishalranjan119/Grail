@isTest
public class OA_BR_YTDCummulativeRevCntrl_Test {
    public static testMethod void testReportData(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
         OA_Budget__c sq = OA_TestDataUtility.createBudget();
        insert sq;
         OA_Monthly_Budget__c mq= OA_TestDataUtility.createMonthlyBudget(sq);
    insert mq;
        List<List<OA_Data_Snapshots__c>> dataSnapList = new List<List<OA_Data_Snapshots__c>>();
        List<OA_Data_Snapshots__c> d = OA_TestDataUtility.createMultipleDataSnapShots(2016);
        
        List<OA_Data_Snapshots__c> d1 = OA_TestDataUtility.createMultipleDataSnapShots(2017);
         
        List<OA_Data_Snapshots__c> d2 = OA_TestDataUtility.createMultipleDataSnapShots(2018);
        
        insert d;
        insert d1;
        insert d2;
        Test.startTest();
        	OA_BR_YTDCummulativeRevCntrl cont = new OA_BR_YTDCummulativeRevCntrl();
        	cont.selectedMonth = String.valueOf(Date.today().month());
        	cont.selectedRegion = 'Europe';
        	cont.selectedYear = String.valueOf(date.today().year());
        	cont.prepareReportData();
        
        OA_BR_YTDCummulativeRevCntrl contt = new OA_BR_YTDCummulativeRevCntrl();
        	contt.selectedMonth = String.valueOf(Date.today().month());
        	contt.selectedRegion = 'Global';
        	contt.selectedYear = String.valueOf(date.today().year()-3);
        	contt.prepareReportData();
        Test.stopTest();
    }
}