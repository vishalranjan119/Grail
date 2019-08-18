public class OA_OpportunitySplitTriggerHelper {
    public static boolean updateExecute = false;
    public static void beforInsert(List<OpportunitySplit> newlist){
        updateUniqueKey(newlist);
        calcCommisionableAmntInsert(newlist);
    }
    public static void afterUpdate(List<OpportunitySplit> newlist){
        if(!updateExecute) calcCommisionableAmntUpdate(newlist);
       
    }
    
    public static void updateUniqueKey(List<OpportunitySplit> newlist){
        if(newlist == null) return;
        for(OpportunitySplit eachOS : newlist){
            eachOS.External_Id__c =  String.valueOf(eachOS.OpportunityId) 
                					+String.valueOf(eachOS.SplitTypeId) 
                 					+String.valueOf(eachOS.SplitOwnerId);
        }
    }
    
    public static void calcCommisionableAmntInsert(List<OpportunitySplit> newlist){
        
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Double> revenueSplitMap = new Map<Id, Double>();
        
        
        for(OpportunitySplit split : newlist){
            
            oppIds.add(split.OpportunityId);
        }
        List<OpportunitySplit> splitList = new List<OpportunitySplit>(
            [SELECT SplitType.MasterLabel, SplitTypeId, External_Id__c, OpportunityId, SplitOwnerId, SplitAmount, SplitPercentage FROM OpportunitySplit WHERE OpportunityId IN : oppIds AND SplitType.MasterLabel = 'Revenue']
        );
        
        for(OpportunitySplit split :splitList){
            revenueSplitMap.put(split.SplitOwnerId, split.SplitAmount);           
        }
        
        for(OpportunitySplit split : newlist){          
            if(revenueSplitMap.containsKey(split.SplitOwnerId)){
                split.OA_Commissionable_Amount__c = (split.SplitPercentage * revenueSplitMap.get(split.SplitOwnerId))/100;   
               
            }
            
        }
    }
    
    public static void calcCommisionableAmntUpdate(List<OpportunitySplit> newlist){
         System.debug('************** SPLIT Update Trigger****************'); 
        Set<Id> oppIds = new Set<Id>();
        Map<Id, OpportunitySplit> revenueSplitMap = new Map<Id, OpportunitySplit>();
        Map<Id, OpportunitySplit> commisionableSplitMap = new Map<Id, OpportunitySplit>();
        
        for(OpportunitySplit split : newlist){
            oppIds.add(split.OpportunityId);
        }
        List<OpportunitySplit> splitList = new List<OpportunitySplit>(
            [SELECT SplitType.MasterLabel, SplitTypeId, External_Id__c, OpportunityId, SplitOwnerId, SplitAmount, SplitPercentage FROM OpportunitySplit WHERE OpportunityId IN : oppIds]
        );
        
        for(OpportunitySplit split :splitList){
            if(split.SplitType.MasterLabel == 'Revenue') revenueSplitMap.put(split.SplitOwnerId, split);
            if(split.SplitType.MasterLabel == 'Commissionable Amount') commisionableSplitMap.put(split.SplitOwnerId, split);                           
        }
        List<OpportunitySplit> splitToBeUpdated = new List<OpportunitySplit>();
        for(String key : commisionableSplitMap.keyset()){            
            splitToBeUpdated.add(new OpportunitySplit(
                Id = commisionableSplitMap.get(key).Id,
                OA_Commissionable_Amount__c = revenueSplitMap.containsKey(key) ?  (commisionableSplitMap.get(key).SplitPercentage * revenueSplitMap.get(key).SplitAmount)/100 : 0
            ));
        }
        updateExecute = true;
        update splitToBeUpdated;
        updateExecute = false;
        
    }

}