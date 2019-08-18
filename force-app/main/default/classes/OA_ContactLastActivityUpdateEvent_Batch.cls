/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_ContactLastActivityUpdateEvent_Batch
Class Purpose: Batch to update the Last Activity Date on Contacts
Versions: 1.1
******************************************************************************************************/
global class OA_ContactLastActivityUpdateEvent_Batch implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc){        
        String query = 'SELECT Id, ActivityDate FROM Event WHERE ActivityDate='+String.valueOf(System.today());
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Event> scope){
        OA_ActivityUtil.updateLastActivityOnContact(scope);
    }
    
    global void finish(Database.BatchableContext bc){
    
    }
        
    global void execute(SchedulableContext sc){
        OA_ContactLastActivityUpdateEvent_Batch runBatch = new OA_ContactLastActivityUpdateEvent_Batch();
        Database.executeBatch(runBatch,200);
    }

}