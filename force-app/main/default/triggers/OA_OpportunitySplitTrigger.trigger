trigger OA_OpportunitySplitTrigger on OpportunitySplit (before insert, after update) {
    if(Trigger.isBefore && Trigger.isInsert)
		OA_OpportunitySplitTriggerHelper.beforInsert(Trigger.new);
    if(Trigger.isAfter && Trigger.isUpdate){
        OA_OpportunitySplitTriggerHelper.afterUpdate(Trigger.new);       
    }       
	
}