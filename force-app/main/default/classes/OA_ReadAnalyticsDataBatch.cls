/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_ReadAnalyticsDataBatch
Class Purpose: Batch class to read the Google Analytics Data for Campaign and campaign Member
Versions: 1.1
*****************************************************************************************************/

global class OA_ReadAnalyticsDataBatch implements Database.Batchable<sObject>, Schedulable {
   
    public List<Campaign> CmpList=new List<Campaign>();
    public List<Campaign> UpdateCampaignsList=new List<Campaign>();
    public List<Campaignmember>UpdateCampaignMemberList =new List<Campaignmember>();
    public List<Campaignmember> UpdateMembers=new List<Campaignmember>();
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        String query = 'select id,OA_Campaign_ID__c,OA_Lead_ID__c,OA_Contact_ID__c,OA_Hits__c from OA_GAnalytics__c';
        return Database.getQueryLocator(query);
    }
    
    public Boolean isValidId(String s) {
        
        Id validId;
        
        try {
            
            validId = s;
            
            return true;
            
        } catch (Exception ex) {
            
            return false;
            
        }
        
    }
    
    global void execute(Database.BatchableContext context, List<OA_GAnalytics__c> scope) {
        Set<Id> GAIds = new Set<Id>();
        
        for (OA_GAnalytics__c ga : scope) {
            Boolean chkid =isValidId((string)(ga.OA_Campaign_ID__c));
                if (chkid==true)   {
            if(ga.OA_Campaign_ID__c!='(not set)'){
                GAIds.add(Id.Valueof(ga.OA_Campaign_ID__c));
            }
                }}
        List<Campaign>CmpList=[select id, name ,OA_Website_Hits__c from Campaign where id IN: GAIds];
        Map<Id,Double> UpdateCampaign=new Map<Id,Double>();
        Map<Id,Double> UpdateCampaignMember=new Map<Id,Double>();
        List<AggregateResult> GAlist=[select OA_campaign_ID__c,sum(OA_Hits__c) from OA_GAnalytics__c GROUP BY OA_campaign_ID__c ];
        List<AggregateResult> CmpMemlist=[select OA_Contact_ID__c,OA_campaign_ID__c,OA_Lead_ID__c,sum(OA_Hits__c) from OA_GAnalytics__c GROUP BY OA_campaign_ID__c, OA_Contact_ID__c,OA_Lead_ID__c];
        for (AggregateResult result : GAlist) {
            Boolean chkid =isValidId((string)(result.get('OA_campaign_ID__c')));
                if (chkid==true)   {
            if((result.get('OA_campaign_ID__c')!='(not set)')&(result.get('OA_campaign_ID__c')!='(not provided)')){
               
                    Id CampId = (Id) result.get('OA_campaign_ID__c');
                    double total = (double) result.get('expr0');
                    
                    UpdateCampaign.put(CampId,total);
                    system.debug(UpdateCampaign);
                }                    
                
            }
        } 
        
        for (AggregateResult result : CmpMemlist) {
            if(result.get('OA_Campaign_ID__c')!='(not set)' ){
                if(result.get('OA_Lead_ID__c')!='(not set)' || result.get('OA_Lead_ID__c')!='(not provided)' ){
                    if( result.get('OA_Contact_ID__c')!='(not provided)' || result.get('OA_Contact_ID__c')!='(not set)') { 
                        String UiD = (String) result.get('OA_Lead_ID__c');
                        String Cid =  (String)result.get('OA_Contact_ID__c');
                        String CmpId = (String)result.get('OA_campaign_ID__c');
                        double total = (double) result.get('expr0');
                        system.debug(UiD+'*****'+Cid+'*****'+CmpId+'*****'+total);
                        if(UiD!='(not set)' || Cid!='(not set)'){
                            CampaignMember[] cm = [select id,type,OA_WebHits__c from Campaignmember where campaignId=:CmpId AND (ContactId=:Cid OR LeadId=:UiD)];
                            system.debug(cm);
                            
                            if(!cm.isEmpty()){
                                for(CampaignMember c:cm){
                                    UpdateCampaignMemberList.add(c);
                                    UpdateCampaignMember.put(c.Id,total);
                                    system.debug(UpdateCampaignMember);
                                }
                            }
                        } 
                    }}}}
        for (Id id : UpdateCampaign.keySet()) {
            updateCampaignsList.add(new Campaign(Id = id, OA_Website_Hits__c = UpdateCampaign.get(id)));
        }
        
        for (Id id : UpdateCampaignMember.keySet()) {
            UpdateMembers.add(new CampaignMember(Id = id,  OA_WebHits__c = UpdateCampaignMember.get(id)));
        }
        update UpdateCampaignsList;
        update UpdateMembers;
        system.debug(UpdateMembers);
        system.debug(CmpList);
        system.debug(GAlist);
        
    }
    global void execute(SchedulableContext context){
        OA_ReadAnalyticsDataBatch batchJob = new OA_ReadAnalyticsDataBatch();
        Database.executeBatch(batchJob);
    }
    
    public void finish(Database.BatchableContext context) {
    }
    
}