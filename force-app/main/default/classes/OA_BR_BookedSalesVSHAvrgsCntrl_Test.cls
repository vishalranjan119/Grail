@isTest
public class OA_BR_BookedSalesVSHAvrgsCntrl_Test {
public static testMethod void validateReport(){
        Account a = OA_TestDataUtility.createAccount();
        insert a;
        Sales_Quota__c sq = OA_TestDataUtility.createRegionalSalesQuota();
        insert sq;
         List<List<OA_Data_Snapshots__c>> dataSnapList = new List<List<OA_Data_Snapshots__c>>();
        List<OA_Data_Snapshots__c> d1 = OA_TestDataUtility.createMultipleDataSnapShots(2016);
        
        List<OA_Data_Snapshots__c> d2 = OA_TestDataUtility.createMultipleDataSnapShots(2017);
       
        List<OA_Data_Snapshots__c> d3 = OA_TestDataUtility.createMultipleDataSnapShots(2018);
        insert d1;
        insert d2;
        insert d3;
        Test.startTest();
        	OA_BR_BookedSalesVSHAvrgsCntrl cont = new OA_BR_BookedSalesVSHAvrgsCntrl();
        	cont.selectedMonth=String.valueOf(Date.today().month());
            cont.selectedYear=String.valueOf(date.today().year()-1);
            cont.prepareReportData();
          OA_BR_BookedSalesVSHAvrgsCntrl contt = new OA_BR_BookedSalesVSHAvrgsCntrl();
        	contt.selectedMonth=String.valueOf(Date.today().month());
            contt.selectedYear=String.valueOf(date.today().year());
            contt.prepareReportData();
           
        Test.stopTest();
    
     
    }
}