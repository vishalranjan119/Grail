/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_AccountActivityOverdueCheck_Batch
Class Purpose: Batch to update the Activity Overdue Checkbox on Account Object
Versions: 1.1
******************************************************************************************************/
public class OA_RevenueForecastTriggerHandler {
    
    public static void beforeInsert(List<OA_Revenue_Forecast__c> newlist){
        populateProjectOwner(newlist);        
    }
    
    public static void beforeUpdate(List<OA_Revenue_Forecast__c> newlist, Map<Id, OA_Revenue_Forecast__c> oldMap){
        Integer currentMonth = System.today().month();
        Integer currentYear = System.today().year();
        for(OA_Revenue_Forecast__c forecast :newlist){
            if(forecast.OA_Month__c == null || forecast.OA_Year__c == null) continue;
            OA_Revenue_Forecast__c oldForecast = oldMap.get(forecast.Id);
            if((Integer.valueOf(forecast.OA_Month__c) < currentMonth) && 
               (Integer.valueOf(forecast.OA_Year__c) <= currentYear) && 
               forecast.OA_Percentage_Invoiced__c != oldForecast.OA_Percentage_Invoiced__c){                
                //forecast.addError(Label.Past_due_date_error);
            }
            
            if(forecast.RecordTypeId != oldForecast.RecordTypeId || 
               forecast.OA_Month__c != oldForecast.OA_Month__c ||
               forecast.OA_Year__c != oldForecast.OA_Year__c
              ){
                  populateUniqueIdentifier(forecast);
              }
        }
    }
    
    private static void populateProjectOwner(List<OA_Revenue_Forecast__c> newlist){
        Set<Id> oppIds = new Set<Id>();
        for(OA_Revenue_Forecast__c newForecast : newlist){
            oppIds.add(newForecast.OA_Opportunity__c);
        }
        
        Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>(
            [SELECT Id, OwnerId FROM Opportunity WHERE ID IN : oppIds]
        );
        
        for(OA_Revenue_Forecast__c newForecast : newlist){
            newForecast.OA_Project_Owner__c = opportunities.get(newForecast.OA_Opportunity__c).OwnerId;
            populateUniqueIdentifier(newForecast);            
        }        
    }
    
    private static void populateUniqueIdentifier(OA_Revenue_Forecast__c newForecast){
			
            newForecast.OA_Unique_Identifier__c = String.valueOf(newForecast.OA_Opportunity__c)
                +String.valueOf(newForecast.RecordTypeId)
                +String.valueOf(newForecast.OA_Month__c)
                +String.valueOf(newForecast.OA_Year__c); 
    }
}