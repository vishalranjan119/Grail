trigger OA_AccountTrigger on Account (before delete) {
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            OA_AccountTriggerHandler.beforeDelete(Trigger.Old);
        }
    }
}