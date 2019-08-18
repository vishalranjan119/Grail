@isTest
public class OA_BR_WeightedGrossPipelineCntrl_Test {
 public static testMethod void testReportData(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        Sales_Quota__c sq = OA_TestDataUtility.createRegionalSalesQuota();
        insert sq;
        List<OA_Data_Snapshots__c> dataSnapList = new List<OA_Data_Snapshots__c>();
        OA_Data_Snapshots__c d = OA_TestDataUtility.createDataSnapShots();
        d.OA_Probability__c = 50;
        d.OA_Region__c = 'Europe';
        OA_Data_Snapshots__c d1 = OA_TestDataUtility.createDataSnapShots();
        d1.OA_Probability__c = 80;
        d1.OA_Region__c = 'APAC & MEA';
        OA_Data_Snapshots__c d2 = OA_TestDataUtility.createDataSnapShots();
        d2.OA_Probability__c = 100;
        d2.OA_Region__c = 'East NA';
        dataSnapList.add(d);
        dataSnapList.add(d1);
        dataSnapList.add(d2);
        insert dataSnapList;
        Test.startTest();
        	OA_BR_WeightedGrossPipelineCntrl cont = new OA_BR_WeightedGrossPipelineCntrl();
        	cont.apacProbability='70';
            cont.eastCoatsProbability='60';
            cont.europeProbability='70';
            cont.westCoatsProbability='50';
            cont.selectedMonth = String.valueOf(Date.today().month());
            cont.selectedYear = String.valueOf(date.today().year());
     
        	cont.prepareReportData();
        Test.stopTest();
    }
}