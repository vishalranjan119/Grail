@isTest
public class OA_BR_ResrchPipelineOverviewCntrl_Test {
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
        
        
        dataSnapList.add(d);
        dataSnapList.add(d1);
        dataSnapList.add(d2);
        
        insert dataSnapList;
        Test.startTest();
        OA_BR_ResrchPipelineOverviewCntrl cont = new OA_BR_ResrchPipelineOverviewCntrl();
        cont.selectedMonth = String.valueOf(Date.today().month());
        cont.selectedYear = String.valueOf(date.today().year());
        cont.selectedRegion ='Europe';
        cont.prepareReportData();
    
        OA_BR_ResrchPipelineOverviewCntrl contt = new OA_BR_ResrchPipelineOverviewCntrl();
        contt.selectedMonth = String.valueOf(Date.today().month());
        contt.selectedYear = String.valueOf(date.today().year()-1);
        contt.selectedRegion ='Europe';
        contt.prepareReportData();
        Test.stopTest();
    }
    
}