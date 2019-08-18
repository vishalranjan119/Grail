/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_ReadHtmlEmailStatusContactsBatch
Class Purpose: Batch class to read the HTML email opened status for Contacts
Versions: 1.1
******************************************************************************************************/
global class OA_ReadHtmlEmailStatusContactsBatch implements Database.Batchable<sObject>, Schedulable {
    global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT id, ( SELECT id, taskid, whoid, createddate, FirstOpenDate, EmailTemplateName, timesopened  FROM EmailStatuses WHERE EmailTemplateName <> \'\') FROM Contact';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Contact> scope){
        Map<String, List<Contact>> campNContactsMap = new Map<String,List<Contact>>();
        Map<String,Integer> campaignNames = new Map<String,Integer>();
        List<Campaign> campUpdateList = new List<Campaign>();
        List<CampaignMember> campMemberToUpdate = new List<CampaignMember>();
        for(Contact c : scope){
            for(EmailStatus ems : c.EmailStatuses){
                String origCampName = '';
                if(ems.EmailTemplateName.contains('_')){
                    origCampName = ems.EmailTemplateName.subStringBefore('_');
                }
                else{
                    origCampName = ems.EmailTemplateName;
                }
                if(!campaignNames.containsKey(origCampName)){
                    campaignNames.put(origCampName,ems.timesopened);    
                }
                else{
                    Integer updatedCount = campaignNames.get(origCampName) + ems.timesopened;
                    campaignNames.put(origCampName,updatedCount);
                }
                if(ems.timesopened > 0){                
                    if(!campNContactsMap.containsKey(origCampName)){
                        campNContactsMap.put(origCampName,new List<Contact>());
                    }                
                    if(campNContactsMap.containsKey(origCampName)){
                        campNContactsMap.get(origCampName).add(c);
                    }    
                }    
            }
        }
        System.debug('***'+campNContactsMap);
        for(Campaign c : [SELECT id, Name, Count_Of_emails_opened_by_Contacts__c, (SELECT Id, CampaignId, LeadId, ContactId, Status, HasResponded, Name, FirstName, LastName FROM CampaignMembers) FROM Campaign WHERE Name IN: campNContactsMap.keySet()]){
            if(campaignNames.containsKey(c.Name)){
                c.Count_Of_emails_opened_by_Contacts__c = campaignNames.get(c.Name);   
                campUpdateList.add(c);
            }
            for(CampaignMember cm : c.CampaignMembers){
                for(Contact con : campNContactsMap.get(c.Name)){
                    if(con.id == cm.ContactId){
                        cm.Status = 'Responded';
                        campMemberToUpdate.add(cm);
                    }
                }
            }
        }
        Database.update(campMemberToUpdate);
        Database.update(campUpdateList);
    }   
    global void finish(Database.BatchableContext bc){
    
    }
    global void execute(SchedulableContext sc){
        OA_ReadHtmlEmailStatusContactsBatch runBatch = new OA_ReadHtmlEmailStatusContactsBatch();
        Database.executeBatch(runBatch,200);
    }
}