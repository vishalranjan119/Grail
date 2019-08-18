/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_ActivityUtil
Class Purpose: Utility class for Activity functionalities
Versions: 1.1
******************************************************************************************************/
public class OA_ActivityUtil {
    
    public static void updateLastActivityOnContact(List<Task> newlist, Map<Id, SObject> oldmap){
        Set<Id> completedTaskIds = new Set<Id>();
        Map<Id, Date> completedDateMap = new Map<Id, Date>();
        for(Task newTask : newlist){
            Task oldTask = (Task)oldmap.get(newTask.Id);
            if(oldTask.Status != newTask.Status && newTask.Status.equalsIgnoreCase('Completed')){
                completedTaskIds.add(newTask.Id);
                completedDateMap.put(newTask.Id, newTask.ActivityDate);
            } 
        }
        List<TaskRelation> relations = new List<TaskRelation>(
            [SELECT RelationId, Relation.Name, IsWhat, TaskId from TaskRelation WHERE TaskId IN : completedTaskIds]
        ); 
        updateContacts(relations,completedDateMap, 'TaskId');
    }
    
    
    public static void updateLastActivityOnContact(List<Event> activities){
        Set<Id> eventIds = new Set<Id>();
        Map<Id, Date> completedDateMap = new Map<Id, Date>();
        for(Event newEvent : activities){            
            eventIds.add(newEvent.Id);
            completedDateMap.put(newEvent.Id, newEvent.ActivityDate);            
        }
        List<EventRelation> relations = new List<EventRelation>(
            [SELECT RelationId, Relation.Name, IsWhat, EventId from EventRelation WHERE EventId IN : eventIds]
        ); 
        updateContacts(relations,completedDateMap, 'EventId');        
    }
    
    private static void updateContacts(List<SObject> relations, Map<Id, Date> activityIdCloseDateMap, String parentField){
        if(relations == null || relations.isEmpty()) return;
        List<SObject> sObjectsToUpdate = new List<SObject>();
        
        System.debug('relations:'+relations.size());
        for(SObject eachRelation : relations){
            Id relationId = (Id)eachRelation.get('RelationId');            
            SObject sObj = relationId.getSobjectType().newSObject();
            System.debug(String.valueOf(sObj.getSObjectType()));
            if(String.valueOf(sObj.getSObjectType()) == 'Contact'){
                sObj.put('id', relationId); 
                sObj.put('Last_Activity__c', activityIdCloseDateMap.get((Id)eachRelation.get(parentField)));            
                sObjectsToUpdate.add(sObj);
            }
        }
        
        System.debug('sObjectsToUpdate:'+sObjectsToUpdate.size());
        if(!sObjectsToUpdate.isEmpty()){
            Database.update(sObjectsToUpdate, false);
        }
    }
    
    

}