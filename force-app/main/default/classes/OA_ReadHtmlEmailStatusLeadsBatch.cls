/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_ReadHtmlEmailStatusLeadsBatch
Class Purpose: Batch class to read the HTML email opened status for Leads
Versions: 1.1
******************************************************************************************************/
global class OA_ReadHtmlEmailStatusLeadsBatch implements Database.Batchable<sObject>, Schedulable {
	global Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT id, ( SELECT id, taskid, whoid, createddate, FirstOpenDate, EmailTemplateName, timesopened  FROM EmailStatuses WHERE EmailTemplateName <> \'\' ) FROM Lead';
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Lead> scope){
        Map<String, List<Lead>> campNLeadsMap = new Map<String,List<Lead>>();
        Map<String,Integer> campaignNames = new Map<String,Integer>();
        List<Campaign> campUpdateList = new List<Campaign>();
        List<CampaignMember> campMemberToUpdate = new List<CampaignMember>();
        for(Lead l : scope){
            for(EmailStatus ems : l.EmailStatuses){
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
                    if(!campNLeadsMap.containsKey(origCampName)){
                        campNLeadsMap.put(origCampName,new List<Lead>());
                    }                
                    if(campNLeadsMap.containsKey(origCampName)){
                        campNLeadsMap.get(origCampName).add(l);                        
                    }
                }    
            }
        }
        System.debug('***'+campNLeadsMap);
        for(Campaign c : [SELECT id, Name, Emails_Opened_By_Leads__c, (SELECT Id, CampaignId, LeadId, ContactId, Status, HasResponded, Name, FirstName, LastName FROM CampaignMembers) FROM Campaign WHERE Name IN: campNLeadsMap.keySet()]){
            if(campaignNames.containsKey(c.Name)){
            	c.Emails_Opened_By_Leads__c = campaignNames.get(c.Name);   
                campUpdateList.add(c);
            }
            for(CampaignMember cm : c.CampaignMembers){
                for(Lead l : campNLeadsMap.get(c.Name)){
                    if(l.id == cm.LeadId){
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
        OA_ReadHtmlEmailStatusLeadsBatch runBatch = new OA_ReadHtmlEmailStatusLeadsBatch();
        Database.executeBatch(runBatch,200);
    }
}