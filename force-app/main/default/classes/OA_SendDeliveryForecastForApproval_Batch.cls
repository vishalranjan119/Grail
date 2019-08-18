/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_SendDeliveryForecastForApproval_Batch
Class Purpose: Batch to trigger the Approval Process for Revenue Forecast Object records
Versions: 1.2
1.1: Added check for Opportunity status
******************************************************************************************************/
global class OA_SendDeliveryForecastForApproval_Batch implements Database.Batchable<sObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc){
        String month = '\''+ String.valueOf(System.today().month())+ '\'';
        String year  = '\''+ String.valueOf(System.today().year()) + '\'';
        Set<String> allowedStatus = new Set<String>{'Planned','Delivery In Progress'};
        Set<String> oppAllowedStatus = new Set<String>{'Closed Won'};
        String query = 'SELECT CreatedBy.Name, OA_Status__c,OA_Forecast_Month__c, RecordType.Name, RecordType.DeveloperName, OA_Opportunity__c, OA_Comment__c FROM OA_Revenue_Forecast__c WHERE OA_Month__c ='+ month+' AND OA_Year__c ='+ year+' AND OA_Status__c IN : allowedStatus AND OA_Opportunity__r.StageName IN: oppAllowedStatus';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<OA_Revenue_Forecast__c> scope){      
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        for(OA_Revenue_Forecast__c forecast : scope){ 
            if(!Approval.isLocked(forecast)){             
                Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                approvalRequest.setComments('Submitting request for approval.');
                approvalRequest.setObjectId(forecast.id);            
                if(forecast.RecordType.Name != null && forecast.RecordType.DeveloperName.equalsIgnoreCase(OA_Constant.DELIVERY)) {               
                    approvalRequest.setProcessDefinitionNameOrId('OA_Delivery_Forecast_Approval');
                }
                if(forecast.RecordType.Name != null && forecast.RecordType.DeveloperName.equalsIgnoreCase(OA_Constant.INVOICE)){               
                    approvalRequest.setProcessDefinitionNameOrId('OA_Invoice_Forecast_Approval');
                }
                requests.add(approvalRequest);
            }    
        }        
        try{           
            System.debug('***'+requests);
            Approval.ProcessResult[] processResults = Approval.process(requests, false);
            for(Approval.ProcessResult result: processResults){
                System.debug('result:'+String.valueOf(result.getErrors()));
            }
        }catch(Exception ex){
            System.debug('Exception:'+ex.getMessage());
        }
        
    }
    
    global void finish(Database.BatchableContext bc){
        System.debug('Batch Finished');
    }
        
    global void execute(SchedulableContext sc){
        OA_SendDeliveryForecastForApproval_Batch runBatch = new OA_SendDeliveryForecastForApproval_Batch();
        Database.executeBatch(runBatch,1);
    }    
}