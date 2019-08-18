trigger OA_RevenueForecastTrigger on OA_Revenue_Forecast__c (before insert, before Update) {
    If(Trigger.isBefore && Trigger.isInsert){
        OA_RevenueForecastTriggerHandler.beforeInsert(trigger.new);
    }
    If(Trigger.isBefore && Trigger.isUpdate){
        OA_RevenueForecastTriggerHandler.beforeUpdate(trigger.new, trigger.oldMap);
    }
    
}