@isTest
public class OA_BR_BudgetvsForecastPageCntrl_Test {
    public static testMethod void validateReport(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        Sales_Quota__c sq = OA_TestDataUtility.createRegionalSalesQuota();
        insert sq;
        OA_Monthly_Quota__c mq= OA_TestDataUtility.createMonthlyQuota(sq);
        insert mq;
        List<OA_Data_Snapshots__c> dataSnapList = new List<OA_Data_Snapshots__c>();
        OA_Data_Snapshots__c d = OA_TestDataUtility.createDataSnapShots();
        
        OA_Data_Snapshots__c d1 = OA_TestDataUtility.createDataSnapShots();
        d1.OA_Probability__c = 100;
        
        OA_Data_Snapshots__c d2 = OA_TestDataUtility.createDataSnapShots();
        
        d2.OA_Region__c = '';
        d2.OA_Year__c='2018';
        
        
        dataSnapList.add(d);
        dataSnapList.add(d1);
        dataSnapList.add(d2);
        
        insert dataSnapList;
        
        Test.startTest();
        
        OA_BR_BudgetvsForecastPageCntrl contt = new  OA_BR_BudgetvsForecastPageCntrl();
        contt.selectedRegion='Europe';
        contt.selectedMonth=String.valueOf(Date.today().month()-1);
        contt.selectedYear=String.valueOf(date.today().year()-1);
        contt.prepareReportData();
        
        OA_BR_BudgetvsForecastPageCntrl cont = new  OA_BR_BudgetvsForecastPageCntrl();
        cont.selectedRegion='Europe';
        cont.selectedMonth=String.valueOf(Date.today().month());
        cont.selectedYear=String.valueOf(date.today().year());
        cont.prepareReportData();
        
        Test.stopTest();
        
        
        
        
    }
}