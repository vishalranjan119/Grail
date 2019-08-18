trigger OA_TaskTrigger on Task (before update) {
	OA_ActivityUtil.updateLastActivityOnContact(Trigger.new, Trigger.oldMap);
}