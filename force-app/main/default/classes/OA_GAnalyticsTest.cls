/******************************************************************************************************
Developed By: OnActuate
Class Name:OA_GAnalyticsTest
Class Purpose: Test Class for OA_GoogleAnalyticsController
Versions: 1.1
*****************************************************************************************************/
@isTest
public class OA_GAnalyticsTest {
   
    @isTest static void testPostCallout() {
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class , new OA_AnalyticsCalloutMock()); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock. 
        HttpResponse response =OA_GoogleAnalyticsController.getGACount();
        // Verify that the response received contains fake values
        String contentType = response.getHeader('Content-Type');
        System.assert(contentType == 'application/json');
        String actualValue = response.getBody();
        System.debug(response.getBody());
        System.assertEquals(200, response.getStatusCode());
    }
    @isTest static void testBatch() {
        OA_GAnalytics__c[] GAList = new List<OA_GAnalytics__c>();
        OA_GAnalytics__c[] GList = new List<OA_GAnalytics__c>();
        for (Integer i=0;i<100;i++) {
            OA_GAnalytics__c m = new OA_GAnalytics__c( OA_Hits__c=1,CurrencyIsoCode='USD',OA_Campaign_ID__c='(not set)',OA_Lead_ID__c='(not set)');
            GAList.add(m);
        }
        Campaign c= new Campaign();
        c.CurrencyIsoCode='USD';
        c.Name=' New Campaign';
        insert c;
        Lead l=new Lead();
        l.FirstName= 'new Lead';
        l.LastName= 'new Lead';
        l.Company='OA';
        insert l;
        Contact co=new Contact();
        co.LastName='new Contact';
        co.CurrencyIsoCode='USD';
        insert co;
        for (Integer i=0;i<50;i++) {
            OA_GAnalytics__c m = new OA_GAnalytics__c( OA_Hits__c=1,CurrencyIsoCode='USD',OA_Lead_ID__c=l.id,OA_Campaign_ID__c=c.Id);
            GList.add(m);
        }
        //insert GAList;
        insert GList;
        Test.startTest();
        OA_ReadAnalyticsDataBatch obj= new OA_ReadAnalyticsDataBatch();
        Database.executebatch(obj);
        
        Test.stopTest();
    }
    
    @isTest static void testanalyticsSync(){
        Test.setMock(HttpCalloutMock.class , new OA_AnalyticsCalloutMock()); 
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        System.Schedule('SampleJob', CRON_EXP, new OA_ScheduleGAnalyticsJobBatch() );   
        Test.stopTest();
        
    } 
}