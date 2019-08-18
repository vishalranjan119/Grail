/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_SnapshotsBatch
Class Purpose: Batch class to create data snapshots records on Monthly Basis
Versions: 1.1
******************************************************************************************************/
global class OA_SnapshotsBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful {
    Integer totalCount = 0;
    Integer successCount = 0;
    Integer failedCount = 0;
    List<String> failedIds = new List<String>();
    
    global Database.QueryLocator start(Database.BatchableContext bc){
       
        String currentYearVal = String.valueOf(Date.today().year());
        delete [Select Id from OA_Data_Snapshots__c 
                WHERE Snapshot_Month__c =: String.valueOf(date.today().month()) 
                AND OA_Year__c =: currentYearVal
                LIMIT 9999                    
               ];
        String query = 'SELECT id, name, AccountId, Account.Name, Probability, OA_Parent_Project__c, RecordType.developerName, OA_Parent_Project__r.Account.Name, OwnerId, OA_Owner_Region__c, (Select id, convertCurrency(OA_Sales_Revenue__c), OA_Month__c, convertCurrency(OA_Risk_Adjusted__c), convertCurrency(OA_Total_Sales_Revenue_Incl_CRs__c) FROM OA_Revenue_Forecasts__r WHERE RecordType.DeveloperName = \'Delivery\' AND OA_Year__c = \'' + currentYearVal + '\') FROM Opportunity WHERE Probability <> 0 AND RecordType.developerName = \'Project\' AND Id IN (Select OA_Opportunity__c FROM OA_Revenue_Forecast__c WHERE RecordType.DeveloperName = \'Delivery\' AND OA_Year__c = \'' + currentYearVal + '\')';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Opportunity> scope){
        System.debug('******** Execute Method Executing **************');

        List<OA_Data_Snapshots__c> snapList = new List<OA_Data_Snapshots__c>();		
        totalCount += scope.size();
        for(Opportunity opp : scope){
            if(opp.OA_Revenue_Forecasts__r.size() > 0){
                OA_Data_Snapshots__c ds = new OA_Data_Snapshots__c();
                ds.Opportunity_Name__c = opp.Name;
                ds.OA_Opportunity__c = opp.Id;
                ds.OA_Region__c = opp.OA_Owner_Region__c;
                ds.Snapshot_Month__c = String.valueOf(date.today().month());
                ds.Snapshot_Date__c = Date.today();                 
                ds.Opportunity_Rep__c = opp.OwnerId;
                ds.Account_Name__c = opp.Account.Name;
                ds.OA_Account__c = opp.AccountId;
                ds.OA_Probability__c = opp.Probability;
                ds.Name = String.valueOf(Date.today().Month()) + '-' + String.valueOf(Date.today().Year()) + String.valueOf(opp.Id);
                ds.OA_User__c = opp.OwnerId;
                ds.OA_Year__c = String.valueOf(Date.today().Year());
                for(OA_Revenue_Forecast__c rev : opp.OA_Revenue_Forecasts__r){
                    if(rev.OA_Month__c == '1'){
                        ds.January__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '2'){
                        ds.February__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '3'){
                        ds.March__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '4'){
                        ds.April__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '5'){
                        ds.May__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '6'){
                        ds.June__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '7'){
                        ds.July__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '8'){
                        ds.August__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '9'){
                        ds.September__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '10'){
                        ds.October__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '11'){
                        ds.November__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                    else if(rev.OA_Month__c == '12'){
                        ds.December__c = opp.Probability == 100 ? rev.OA_Total_Sales_Revenue_Incl_CRs__c : rev.OA_Total_Sales_Revenue_Incl_CRs__c/1000;
                    }
                }
                snapList.add(ds);
        	}
        }
        System.debug('Records Processed : '+snapList.size());
        
        if(!snapList.isEmpty()){        
            List<Database.SaveResult> results = Database.insert(snapList, false);
            integer index = 0;
            for(Database.SaveResult result : results){
                if(!result.isSuccess()){
                    failedCount += 1;
                    String errorMsg = '';
                    for(Database.Error err: result.getErrors()){
                        errorMsg += err.getMessage();
                    }
                    failedIds.add(snapList.get(index).Name+' - '+errorMsg);
                }else{
                    successCount += 1;
                }
                index += 1;
            }            
        }
        
    }  
    
    global void finish(Database.BatchableContext bc){
        System.debug('******** Finish Method Executing **************');
    	sendMail(UserInfo.getUserEmail(), null);
        System.debug('******** Mail Sended **************');
    }
    
    global void execute(SchedulableContext sc){
        OA_SnapshotsBatch runBatch = new OA_SnapshotsBatch();
        Database.executeBatch(runBatch,50);
    }
    
    public void sendMail(String toMail, String ccMail){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        string[] to = new string[] {toMail};
        string[] cc = new string[] {ccMail};         
        email.setToAddresses(to);
        String body = 'Total Record : '+totalCount + '\n';
        body += 'Success Record : '+successCount+ '\n';
        body += 'Failed Record : '+failedCount+ '\n';
        if(failedIds.size() > 0){
             body += JSON.serializePretty(failedIds);
        }
        if(ccMail!=null && ccMail != '')
            email.setCcAddresses(cc);
                 
        email.setSubject('Snapshot Batch Processed');         
        email.setPlainTextBody(body);
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }catch(exception e){
            System.debug('Error:'+e.getMessage()+'\n'+e.getStackTraceString());
        }
         

    }
}