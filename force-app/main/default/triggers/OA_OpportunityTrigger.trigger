trigger OA_OpportunityTrigger on Opportunity (before update, after update, before delete, before insert) {
        if(Trigger.isBefore && Trigger.isInsert){  
            if(!Test.isRunningTest()){ 
            OA_OpportunityTriggerHandler.beforeInsert(Trigger.New);
        }    
    }
    if(trigger.isBefore && trigger.isUpdate){        
        OA_OpportunityTriggerHandler.beforeUpdate(
            Trigger.new,
            Trigger.newMap,
            Trigger.old,
            Trigger.oldMap  
        );
       
    }
    if(trigger.isAfter && trigger.isUpdate){
         OA_OpportunityTriggerHandler.afterUpdate(
            Trigger.new,
            Trigger.newMap,
            Trigger.old,
            Trigger.oldMap  
        );
    }
    if(trigger.isDelete){
        OA_OpportunityTriggerHandler.beforeDelete(Trigger.old);
    }
}