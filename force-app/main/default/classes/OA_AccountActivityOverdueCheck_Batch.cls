/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_AccountActivityOverdueCheck_Batch
Class Purpose: Batch to update the Activity Overdue Checkbox on Account Object
Versions: 1.1
******************************************************************************************************/
global class OA_AccountActivityOverdueCheck_Batch implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT id, OA_Activity_Overdue__c, OA_Activity_Frequency__c, Last_Activity__c, LastActivityDate FROM Account WHERE OA_Activity_Frequency__c <> null';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> scope){
        List<Account> accToUpdateList = new List<Account>();
        for(Account acc : scope){            
            if(acc.LastActivityDate <> null && (acc.LastActivityDate.daysBetween(Date.today()) > acc.OA_Activity_Frequency__c)){
                acc.OA_Activity_Overdue__c = TRUE;
            }
            else{
                acc.OA_Activity_Overdue__c = FALSE;
            }
            accToUpdateList.add(acc);
        }
        Database.update(accToUpdateList);
    }
    
    global void finish(Database.BatchableContext bc){
    
    }
    
    global void execute(SchedulableContext sc){
        OA_AccountActivityOverdueCheck_Batch runBatch = new OA_AccountActivityOverdueCheck_Batch();
        Database.executeBatch(runBatch,200);
    }
    //Use less code; kept for backup
    /*for(Contact con : acc.Contacts){
                Integer conDateDiff = con.Last_Activity__c.daysBetween(Date.Today());
                Integer accDateDiff = acc.Last_Activity__c.daysBetween(Date.Today());
                if( (conDateDiff > acc.OA_Activity_Frequency__c) || (accDateDiff >  acc.OA_Activity_Frequency__c) ){
                    acc.OA_Activity_Overdue__c = TRUE;
                }
                else{
                    acc.OA_Activity_Overdue__c = FALSE;
                }
                if(!accToUpdateList.contains(acc)){
                    accToUpdateList.add(acc);
                }    
            }*/
}