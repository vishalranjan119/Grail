/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_TestDataUtility
Class Purpose: Contains test data for consuming in Unit Testing
Versions: 1.1
******************************************************************************************************/

public Class OA_TestDataUtility{
    //Single Account Creation
    public static Account createAccount(){
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.OA_Activity_Frequency__c = 5;
        return acc;
    }
    //Single Contact Creation
    public static Contact createContact(Account a){
        Contact c = new Contact();
        c.AccountId = a.id;
        c.LastName = 'TestingLastName';
        return c;
    }
    //Single Event(Activity) Creation
    public static Event createEvent(Account a){
        Event e = new Event();
        e.WhatId=a.id;
        e.StartDateTime=system.today();
        e.EndDateTime=system.today()+5;
        return e;
    }
    //Single Opportunity Creation
    public static Opportunity createOpportunity(Account a){
        RecordType rtype = [SELECT id FROM RecordType WHERE Name = 'Project'];
        Opportunity opp = new Opportunity();
        opp.AccountId = a.id;
        opp.StageName = 'Closed Won';
        opp.Name = 'Test Opportunity';
        opp.CloseDate = Date.Today();
        opp.RecordTypeId = rType.id;
        opp.OA_Competency__c = 'Activate Sales Strategy';
        
        return opp;
    }
    //Single Revenue Forecast Creation
    public static List<OA_Revenue_Forecast__c> createRevForecast(Opportunity o){
        List<OA_Revenue_Forecast__c> rfList = new List<OA_Revenue_Forecast__c>();
        OA_Revenue_Forecast__c rf = new OA_Revenue_Forecast__c();
        rf.OA_Month__c = '11';
        rf.OA_Year__c = String.valueOf(System.today().year());
        rf.OA_Sales_Revenue__c = 2000;
        rf.OA_Total_Sales_Revenue_Incl_CRs__c = 2000;
        rf.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName = 'Delivery'].Id;
        rf.OA_Opportunity__c = o.Id;
        rfList.add(rf);
        OA_Revenue_Forecast__c rfInvoice = new OA_Revenue_Forecast__c();
        rfInvoice.OA_Month__c = '11';
        rfInvoice.OA_Year__c = String.valueOf(System.today().year());
        
        rfInvoice.OA_Invoice_Amount__c = 20;
        rfInvoice.RecordTypeId = [SELECT id FROM RecordType WHERE DeveloperName = 'Invoice'].Id;
        rfInvoice.OA_Opportunity__c = o.Id;
        rfList.add(rfInvoice);
        return rfList;
    } 
    
    public static Sales_Quota__c createCSOSalesQuota(){
        Sales_Quota__c sq = new Sales_Quota__c();
        sq.OA_CSO__c = UserInfo.getUserId();
        sq.OA_Year__c = String.valueOf(System.today().year());
        sq.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Agent_Target'].Id;
        return sq;
    }
    
    public static OA_Budget__c createBudget(){
        User regionUser = [Select id, Region__c from User where id =: UserInfo.getUserId()];
        OA_Budget__c b = new OA_Budget__c();        
         b.OA_Year__c = String.valueOf(System.today().year());  
        b.OA_Region__c = regionUser.Region__c;
        b.OA_Account__c='Europe';
        b.OA_Total_Budget__c=123660;
        return b;
    }
    
    public static Sales_Quota__c createAccountSalesQuota(Account acc){
        Sales_Quota__c sq = new Sales_Quota__c();        
        sq.OA_Year__c = String.valueOf(System.today().year());
        sq.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Account_Target'].Id;
        sq.OA_Account__c = acc.Id;
        return sq;
    }
    
    public static OA_Monthly_Budget__c createMonthlyBudget(OA_Budget__c b){
        OA_Monthly_Budget__c mb = new OA_Monthly_Budget__c(); 
        mb.January__c=1200;
        mb.February__c=1300;
        mb.March__c=1500;
        mb.OA_Budget__c=b.Id;
        
        return mb;
    }
    
    public static OA_Data_Snapshots__c createDataSnapShots(){
    	OA_Data_Snapshots__c dataSnap = new OA_Data_Snapshots__c();
        dataSnap.Account_Name__c = 'Account Snap';
        dataSnap.Opportunity_Name__c = 'Opportunity Snap';
        dataSnap.OA_Probability__c = 10;
        dataSnap.OA_Region__c = 'Europe';
        dataSnap.Snapshot_Date__c = Date.today();
        dataSnap.Snapshot_Month__c = String.valueOf(Date.today().Month());
        dataSnap.OA_Year__c = String.valueOf(Date.today().year());
        dataSnap.January__c = 10;
        dataSnap.February__c = 10;
        dataSnap.March__c = 10;
        dataSnap.April__c = 10;
        dataSnap.May__c = 10;
        dataSnap.June__c = 10;
        dataSnap.July__c = 10;
        dataSnap.August__c = 10;
        dataSnap.September__c = 10;
        dataSnap.October__c = 10;
        dataSnap.November__c = 10;
        dataSnap.December__c = 10;
        dataSnap.External_Id__c = '1';
        dataSnap.Opportunity_Rep__c = UserInfo.getUserId();
        return dataSnap;
    }
    public static List<OA_Data_Snapshots__c> createMultipleDataSnapShots(Integer yearVal){
        List<OA_Data_Snapshots__c> dataList = new List<OA_Data_Snapshots__c>();
        for(Integer i =1; i< 13; i++){
            OA_Data_Snapshots__c dataSnap = new OA_Data_Snapshots__c();
            dataSnap.Account_Name__c = 'Account Snap 2';
            dataSnap.Opportunity_Name__c = 'Opportunity Snap 2';
            dataSnap.OA_Probability__c = 10;
            dataSnap.OA_Region__c = 'Europe';
            dataSnap.Snapshot_Date__c = Date.newInstance(yearVal,i,15);
            dataSnap.Snapshot_Month__c = String.valueOf(i);
            dataSnap.OA_Year__c = String.valueOf(yearVal);
            dataSnap.January__c = 10;
            dataSnap.February__c = 10;
            dataSnap.March__c = 10;
            dataSnap.April__c = 10;
            dataSnap.May__c = 10;
            dataSnap.June__c = 10;
            dataSnap.July__c = 10;
            dataSnap.August__c = 10;
            dataSnap.September__c = 10;
            dataSnap.October__c = 10;
            dataSnap.November__c = 10;
            dataSnap.December__c = 10;
            dataSnap.External_Id__c = '1';
            dataSnap.Opportunity_Rep__c = UserInfo.getUserId();
            dataList.add(dataSnap);
        	}
        for(Integer i =1; i< 13; i++){
            OA_Data_Snapshots__c dataSnap = new OA_Data_Snapshots__c();
            dataSnap.Account_Name__c = 'Account Snap 3';
            dataSnap.Opportunity_Name__c = 'Opportunity Snap 3';
            dataSnap.OA_Probability__c = 50;
            dataSnap.OA_Region__c = 'APAC & MEA';
            dataSnap.Snapshot_Date__c = Date.newInstance(yearVal,i,15);
            dataSnap.Snapshot_Month__c = String.valueOf(i);
            dataSnap.OA_Year__c = String.valueOf(yearVal);
            dataSnap.January__c = 10;
            dataSnap.February__c = 10;
            dataSnap.March__c = 10;
            dataSnap.April__c = 10;
            dataSnap.May__c = 10;
            dataSnap.June__c = 10;
            dataSnap.July__c = 10;
            dataSnap.August__c = 10;
            dataSnap.September__c = 10;
            dataSnap.October__c = 10;
            dataSnap.November__c = 10;
            dataSnap.December__c = 10;
            dataSnap.External_Id__c = '1';
            dataSnap.Opportunity_Rep__c = UserInfo.getUserId();
            dataList.add(dataSnap);
        	}
        for(Integer i =1; i< 13; i++){
            OA_Data_Snapshots__c dataSnap = new OA_Data_Snapshots__c();
            dataSnap.Account_Name__c = 'Account Snap 4';
            dataSnap.Opportunity_Name__c = 'Opportunity Snap 4';
            dataSnap.OA_Probability__c = 100;
            dataSnap.OA_Region__c = 'West NA';
            dataSnap.Snapshot_Date__c = Date.newInstance(yearVal,i,15);
            dataSnap.Snapshot_Month__c = String.valueOf(i);
            dataSnap.OA_Year__c = String.valueOf(yearVal);
            dataSnap.January__c = 10;
            dataSnap.February__c = 10;
            dataSnap.March__c = 10;
            dataSnap.April__c = 10;
            dataSnap.May__c = 10;
            dataSnap.June__c = 10;
            dataSnap.July__c = 10;
            dataSnap.August__c = 10;
            dataSnap.September__c = 10;
            dataSnap.October__c = 10;
            dataSnap.November__c = 10;
            dataSnap.December__c = 10;
            dataSnap.External_Id__c = '1';
            dataSnap.Opportunity_Rep__c = UserInfo.getUserId();
            dataList.add(dataSnap);
        	}
        for(Integer i =1; i< 13; i++){
            OA_Data_Snapshots__c dataSnap = new OA_Data_Snapshots__c();
            dataSnap.Account_Name__c = 'Account Snap 5';
            dataSnap.Opportunity_Name__c = 'Opportunity Snap 5';
            dataSnap.OA_Probability__c = 90;
            dataSnap.OA_Region__c = 'East NA';
            dataSnap.Snapshot_Date__c = Date.newInstance(yearVal,i,15);
            dataSnap.Snapshot_Month__c = String.valueOf(i);
            dataSnap.OA_Year__c = String.valueOf(yearVal);
            dataSnap.January__c = 10;
            dataSnap.February__c = 10;
            dataSnap.March__c = 10;
            dataSnap.April__c = 10;
            dataSnap.May__c = 10;
            dataSnap.June__c = 10;
            dataSnap.July__c = 10;
            dataSnap.August__c = 10;
            dataSnap.September__c = 10;
            dataSnap.October__c = 10;
            dataSnap.November__c = 10;
            dataSnap.December__c = 10;
            dataSnap.External_Id__c = '1';
            dataSnap.Opportunity_Rep__c = UserInfo.getUserId();
            dataList.add(dataSnap);
        	}
        
        for(Integer i =1; i< 13; i++){
            OA_Data_Snapshots__c dataSnap = new OA_Data_Snapshots__c();
            dataSnap.Account_Name__c = 'Account Snap 5';
            dataSnap.Opportunity_Name__c = 'Opportunity Snap 5';
            dataSnap.OA_Probability__c = 0;
            dataSnap.OA_Region__c = '';
            dataSnap.Snapshot_Date__c = Date.newInstance(yearVal,i,15);
            dataSnap.Snapshot_Month__c = String.valueOf(i);
            dataSnap.OA_Year__c = String.valueOf(yearVal);
            dataSnap.January__c = 10;
            dataSnap.February__c = 10;
            dataSnap.March__c = 10;
            dataSnap.April__c = 10;
            dataSnap.May__c = 10;
            dataSnap.June__c = 10;
            dataSnap.July__c = 10;
            dataSnap.August__c = 10;
            dataSnap.September__c = 10;
            dataSnap.October__c = 10;
            dataSnap.November__c = 10;
            dataSnap.December__c = 10;
            dataSnap.External_Id__c = '1';
            dataSnap.Opportunity_Rep__c = UserInfo.getUserId();
            dataList.add(dataSnap);
        	}
        return dataList;
    }
    
        public static Sales_Quota__c createRegionalSalesQuota(){
        User regionUser = [Select id, Region__c from User where id =: UserInfo.getUserId()];
        Sales_Quota__c sq = new Sales_Quota__c();        
        sq.OA_Year__c = String.valueOf(System.today().year());
        sq.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Regional_Target'].Id;
        sq.OA_Region__c = regionUser.Region__c;
        return sq;
    }
    
       
    public static OA_Monthly_Quota__c createMonthlyQuota(Sales_Quota__c sq){
        OA_Monthly_Quota__c mq = new OA_Monthly_Quota__c(); 
        mq.OA_Month__c = '11';
        mq.OA_Sales_Target__c = sq.Id;
        mq.OA_Sold_Revenue__c = 100;
        //mq.OA_
        return mq;
    }
}