/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_OpportunityTriggerHandler
Class Purpose: Handler class for Opportunity Trigger
Versions: 1.1
******************************************************************************************************/
public class OA_OpportunityTriggerHandler {
    
    static Map<String, String> milestoneRecTypeIdNameMap = OA_Utility.getRecordTypeInfosByName('OA_Revenue_Forecast__c');
    static Map<String, String> oppRecTypeIdNameMap = OA_Utility.getRecordTypeInfosByName('Opportunity');
    public static Boolean toExecute = True;
    private static boolean allowedCRdelete = false;
    public static void beforeUpdate(
        List<Opportunity> newlist, 
        Map<Id, Opportunity> newMap, 
        List<Opportunity> oldList, 
        Map<Id, Opportunity> oldMap)
    {            
        validateClosedWonOpp(newlist, newMap, oldList, oldMap);
        updateDeliveryMilestone(newlist, oldMap);
        calculateInvoicePercentage(newlist, newMap, oldList, oldMap);
    }
    public static void afterUpdate(
        List<Opportunity> newlist, 
        Map<Id, Opportunity> newMap, 
        List<Opportunity> oldList, 
        Map<Id, Opportunity> oldMap)
    {           
        afterChangeRequestClosedWon(newList,newMap,oldMap);
    }
    
    public static void beforeDelete(List<Opportunity> oldlist){
        Set<Id> projectIds = new Set<Id>();
        for(Opportunity newOpp : oldlist){
            if(newOpp.StageName.equalsIgnoreCase('Closed Won') 
               && oppRecTypeIdNameMap.get('Change_Request') == newOpp.RecordTypeId 
               && newOpp.OA_Parent_Project__c != null && !allowedCRdelete){
                   newOpp.addError('You cannot delete closed won Change Request');
               }else if(oppRecTypeIdNameMap.get('Project') == newOpp.RecordTypeId){
                   projectIds.add(newOpp.Id);
               }           
        }
        if(!projectIds.isEmpty()){
            allowedCRdelete = true;
            delete [Select Id from Opportunity WHERE OA_Parent_Project__c IN : projectIds];
            allowedCRdelete = false;            
        }
        Profile p = [SELECT id, name FROM Profile WHERE Name = 'System Administrator'];
        for(Opportunity opp : oldList){
            if(UserInfo.getProfileId() <> p.id 
                && oppRecTypeIdNameMap.get('Project') == opp.RecordTypeId){
                opp.addError('You do not have the access to delete Opportunity records. Kindly contact your System Admin for further assistance.');
            }
        }
    }
    
    
    public static void validateClosedWonOpp(
        List<Opportunity> newlist, 
        Map<Id, Opportunity> newMap, 
        List<Opportunity> oldList, 
        Map<Id, Opportunity> oldMap
    )
    {
        Map<String, String> recTypeMap = oppRecTypeIdNameMap;
        Set<Id> closedWonOppIds = new Set<Id>();
        Set<Id> closedWonCROppIds = new Set<Id>(); 
       
        for(Opportunity newOpp : newlist){                      
            Opportunity oldOpp = oldMap.get(newOpp.Id);            
            if(newOpp.StageName != oldOpp.StageName 
               && newOpp.StageName.equalsIgnoreCase('Closed Won') 
               && recTypeMap.get('Project') == newOpp.RecordTypeId){
                closedWonOppIds.add(newOpp.Id);
            }
            if(newOpp.StageName == oldOpp.StageName 
               && newOpp.StageName.equalsIgnoreCase('Closed Won') 
               && recTypeMap.get('Change_Request') == newOpp.RecordTypeId){
                newOpp.addError('You cannot modify closed won Change Request');
            }
        }
        System.debug('closedWonOppIds:'+closedWonOppIds);
        Map<Id, Opportunity> queriedOppMap = new Map<Id,Opportunity>(
            [SELECT ID,OA_Rate_Card_Price__c,Amount, 
             (SELECT SplitType.MasterLabel FROM OpportunitySplits), 
             (SELECT RecordType.DeveloperName FROM OA_Revenue_Forecasts__r)
              FROM Opportunity
              WHERE Id IN :closedWonOppIds
            ]
        );
        
        List<String> failedValidation;    
        Boolean haveRevenueSpilt;
        Boolean haveCommissionSpilt;
        Boolean haveDeliveryForecast;
        Boolean haveInvoiceForecast;
        for(Id oppId : queriedOppMap.keySet()){            
            failedValidation = new List<String>();
            haveRevenueSpilt = false;
            haveCommissionSpilt = false;
            haveDeliveryForecast = false;
            haveInvoiceForecast = false;
            Opportunity newOpp = newMap.get(oppId);
            Opportunity queriedOpp = queriedOppMap.get(oppId);
            if(newOpp.OA_Rate_Card_Price__c == null) failedValidation.add('Effort Estimate (EE) Price');
            if(newOpp.Amount == null) failedValidation.add('Initial Price to Client(Amount)');
            for(OpportunitySplit split : queriedOpp.OpportunitySplits){
                
                if(split.SplitType.MasterLabel == 'Revenue')               haveRevenueSpilt    = true;
                if(split.SplitType.MasterLabel == 'Commissionable Amount') haveCommissionSpilt = true;               
            }
            for(OA_Revenue_Forecast__c forecast : queriedOpp.OA_Revenue_Forecasts__r){
                if(forecast.RecordType.DeveloperName == 'Delivery') haveDeliveryForecast = true;
                if(forecast.RecordType.DeveloperName == 'Invoice')  haveInvoiceForecast  = true;
            }
           // if(!haveRevenueSpilt) failedValidation.add('OpportunitySplit of type Revenue');
           // if(!haveCommissionSpilt) failedValidation.add('OpportunitySplit of type Commission Percentage');
            if(!haveDeliveryForecast) failedValidation.add('Delivery Milestone');
            if(!haveInvoiceForecast) failedValidation.add('Invoice Milestone');
            if(!failedValidation.isEmpty()) newOpp.addError('Following field value/related records must exist before Closing opportunity:'+String.join(failedValidation, ','));           
        }        
    }
    
    /*public static void updateMonthlyTarget(List<Opportunity> newOppList,Map<Id,opportunity> oldMap){
        Set<Id> oppOwnerSet = new Set<Id>();
        Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>();
        for(Opportunity opp : newOppList){
            if( (oldMap == null && opp.Probability <> null) 
                || (oldMap.containsKey(opp.id) && oldMap.get(opp.id).Probability <> opp.Probability) ){
                    oppOwnerSet.add(opp.OwnerId);
                    oppMap.put(opp.id,opp);
            }
        }
        String currentMonth = String.valueOf(Date.Today().Month());
        List<OA_Monthly_Quota__c> monthlyQuotaList = [SELECT id, OA_Risk_Adjusted_Pipeline__c, OA_Month__c 
                                                      FROM OA_Monthly_Quota__c 
                                                      WHERE OA_Sales_Target__r.ownerId 
                                                      IN: oppOwnerSet 
                                                      AND OA_Month__c =: currentMonth];
        
        for(AggregateResult rev : [SELECT sum(OA_Risk_Adjusted__c), OA_Opportunity__c 
                                    FROM OA_Revenue_Forecast__c 
                                    WHERE OA_Opportunity__c 
                                    IN: oppMap.keySet() GROUP BY OA_Opportunity__c]){
             for(OA_Monthly_Quota__c monthly : monthlyQuotaList){                       
                if(monthly.OA_Sales_Target__r.ownerId == oppMap.get((Id)rev.get('OA_Opportunity__c')).OwnerId){
                    monthly.OA_Risk_Adjusted_Pipeline__c = (Double)rev.get('expr0');
                }
             }
        }        
    }*/
    
    //When Opportunity is not closed won and Opportunity amount is changed, update Invoice Amount.
    //CR : update Invoice Percentage instead of Invoice Amount.
    public static void calculateInvoicePercentage(
        List<Opportunity> newlist, 
        Map<Id, Opportunity> newMap, 
        List<Opportunity> oldList, 
        Map<Id, Opportunity> oldMap){
            
            Set<Id> amountChangedOppIds = new Set<Id>();
            List<OA_Revenue_Forecast__c> listToBeUpdated = new List<OA_Revenue_Forecast__c>();
            for(Opportunity newOpp : newlist){
                Opportunity oldOpp = oldMap.get(newOpp.Id);
                if(newOpp.StageName != OA_Constant.CLOSEDWON && newOpp.Amount != oldOpp.Amount){
                    amountChangedOppIds.add(newOpp.Id);
                }                
            }            
            for(OA_Revenue_Forecast__c revForecast : [SELECT Id,OA_Invoice_Amount__c, OA_Opportunity__c, OA_Percentage_Invoiced__c FROM OA_Revenue_Forecast__c WHERE RecordType.DeveloperName = 'Invoice' AND OA_Opportunity__c IN : amountChangedOppIds]){
                if(newMap.get(revForecast.OA_Opportunity__c).Amount == null || revForecast.OA_Invoice_Amount__c == null) continue;
                revForecast.OA_Percentage_Invoiced__c =   (revForecast.OA_Invoice_Amount__c*100)/(newMap.get(revForecast.OA_Opportunity__c).Amount);
                listToBeUpdated.add(revForecast);
            }
            if(!listToBeUpdated.isEmpty() && !System.isFuture() && !System.isBatch()){
                updateRevenueRecords(JSON.serialize(listToBeUpdated));
            }        
        }
    
    //When Project Closed won for the first time -> Move Project Amount to Total Project Cost
    //and Sales Revenue to OA_Total_Sales_Revenue_Incl_CRs__c 
    public static void updateDeliveryMilestone(List<Opportunity> newOppList,Map<Id,opportunity> oldMap){
        Id recTypeId = oppRecTypeIdNameMap.get('Change_Request');
        List<OA_Revenue_Forecast__c> lstToBeUpdated = new List<OA_Revenue_Forecast__c>();
        Set<Id> oppIdSet = new Set<Id>();
        
        
        for(Opportunity newOpp : newOppList){
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            System.debug('newOpp.StageName:'+newOpp.StageName);
            System.debug('oldOpp.StageName:'+oldOpp.StageName);
            if(newOpp.StageName != oldOpp.StageName &&
               newOpp.StageName == OA_Constant.CLOSEDWON &&
               newOpp.RecordTypeId != recTypeId){
                   newOpp.OA_Total_Project_Cost__c = newOpp.Amount;
                   oppIdSet.add(newOpp.Id);
               }
        }
       
        for(OA_Revenue_Forecast__c rf :[Select Id, OA_Sales_Revenue__c from OA_Revenue_Forecast__c where OA_Opportunity__c IN :oppIdSet AND recordType.DeveloperName = 'Delivery']){
            rf.OA_Total_Sales_Revenue_Incl_CRs__c = rf.OA_Sales_Revenue__c;
            lstToBeUpdated.add(rf);  
        }
        
        System.debug('lstToBeUpdated:'+lstToBeUpdated);
        if(!lstToBeUpdated.isEmpty()){
            Database.update(lstToBeUpdated, false);
        }
        
    }
    
    //When Change Request approved/Closed Won, calculate and update Total Project Cost on parent opportunity
    // and Total Sales Revenue(OA_Total_Sales_Revenue_Incl_CRs__c) on delivery milestone.
  
    public static void afterChangeRequestClosedWon(List<Opportunity> newList, Map<Id,Opportunity> newMap, Map<Id,Opportunity> oldMap){
        Id recTypeId = oppRecTypeIdNameMap.get('Change_Request');
        Set<Id> crOppIds = new Set<Id>();
        Set<Id> parentOppIds = new Set<Id>();
        for(Opportunity o : newList){
            if(o.RecordTypeId == recTypeId               
               && o.OA_Parent_Project__c != null 
               && (oldMap.get(o.id).StageName <> o.StageName )){
                   crOppIds.add(o.id); 
                   parentOppIds.add(o.OA_Parent_Project__c);
               }
        }
        if(crOppIds.isEmpty() || parentOppIds.isEmpty()) return;
        calculateTotalProjectCost(parentOppIds);        
    }
    
    public static void calculateTotalProjectCost(Set<Id> parentOppIds){
        Set<Id> crOppIds = new Set<Id>();
        Map<Id, Double> oppTotalProjectCostMap = new Map<Id, Double>();
        Map<Id, String> parentOppCurrencyMap = new Map<Id, String>();
        List<sObject> lstToBeUpdated = new List<sObject>();
        List<OA_Revenue_Forecast__c> lstToBeUpserted = new List<OA_Revenue_Forecast__c>();
        for(Opportunity opp : [SELECT id, Amount, OA_Parent_Project__c, OA_Parent_Project__r.CurrencyIsoCode, OA_Parent_Project__r.Amount,OA_Parent_Project__r.OA_Total_Project_Cost__c FROM Opportunity WHERE OA_Parent_Project__c IN: parentOppIds AND StageName = 'Closed Won']){
            if(!oppTotalProjectCostMap.containsKey(opp.OA_Parent_Project__c)) oppTotalProjectCostMap.put(opp.OA_Parent_Project__c, opp.OA_Parent_Project__r.Amount);
            oppTotalProjectCostMap.put(opp.OA_Parent_Project__c, oppTotalProjectCostMap.get(opp.OA_Parent_Project__c) + opp.Amount); 
            crOppIds.add(opp.Id);
            parentOppCurrencyMap.put(opp.OA_Parent_Project__c, opp.OA_Parent_Project__r.CurrencyIsoCode);
        }
        for(Id oppId : oppTotalProjectCostMap.keyset()){
            lstToBeUpdated.add(
                new Opportunity(
                    Id = oppId,
                    OA_Total_Project_Cost__c = oppTotalProjectCostMap.get(oppId)
                )
            );
        }
        String uniqueKey;
        Map<String, Double> deliveryMilestoneMap = new Map<String, Double>();       
        for(OA_Revenue_Forecast__c rf :[Select Id, OA_Sales_Revenue__c, OA_Month__c, OA_Year__c, OA_Status__c,OA_Opportunity__r.OA_Parent_Project__c, OA_Unique_Identifier__c,RecordType.DeveloperName,OA_Total_Sales_Revenue_Incl_CRs__c, OA_Opportunity__r.OA_Total_Project_Cost__c, OA_Invoice_Amount__c from OA_Revenue_Forecast__c where OA_Opportunity__c IN :parentOppIds OR OA_Opportunity__c IN:crOppIds]){
            if(rf.RecordType.DeveloperName == OA_Constant.INVOICE && 
               oppTotalProjectCostMap.containsKey(rf.OA_Opportunity__c)){
                   rf.OA_Percentage_Invoiced__c = (rf.OA_Invoice_Amount__c/oppTotalProjectCostMap.get(rf.OA_Opportunity__c))*100;
                   lstToBeUpdated.add(rf);  
                   continue;
            }
            uniqueKey = '';
            if(parentOppIds.contains(rf.OA_Opportunity__c)) uniqueKey = rf.OA_Unique_Identifier__c;
            else if(crOppIds.contains(rf.OA_Opportunity__c)){                 
                uniqueKey = String.valueOf(rf.OA_Opportunity__r.OA_Parent_Project__c)+
                    String.valueOf(rf.RecordTypeId)+
                    rf.OA_Month__c+
                    rf.OA_Year__c;
            }
            if(uniqueKey == '') continue;
            if(!deliveryMilestoneMap.containsKey(uniqueKey)) deliveryMilestoneMap.put(uniqueKey,0); 
            deliveryMilestoneMap.put(uniqueKey, deliveryMilestoneMap.get(uniqueKey) + rf.OA_Sales_Revenue__c);
            
        }
        
        System.debug('deliveryMilestoneMap:'+JSON.serializePretty(deliveryMilestoneMap));
        for(String key : deliveryMilestoneMap.keyset()){
            OA_Revenue_Forecast__c dm = new OA_Revenue_Forecast__c();
            dm.OA_Unique_Identifier__c = key;
            dm.OA_Total_Sales_Revenue_Incl_CRs__c = deliveryMilestoneMap.get(key);                                    
            dm.OA_Opportunity__c = key.substring(0, 18);
            dm.RecordTypeId = key.substring(18, 36);
            dm.OA_Month__c  = key.substring(36).length() > 5 ? key.substring(36,38) : key.substring(36,37);
            dm.OA_Year__c   = key.substring(36).length() > 5 ? key.substring(38) : key.substring(37);
            dm.CurrencyIsoCode = parentOppCurrencyMap.get(key.substring(0, 18));  
            
            lstToBeUpserted.add(dm);
        }
        
        if(!lstToBeUpdated.isEmpty()){
            Database.SaveResult[] results = Database.update(lstToBeUpdated, false);
            Set<Id> updatedOppIds = new Set<Id>();
            for(Database.SaveResult result : results){
               
            }
        }
        if(!lstToBeUpserted.isEmpty()){
            List<Database.UpsertResult> results = Database.upsert(lstToBeUpserted, Schema.OA_Revenue_Forecast__c.OA_Unique_Identifier__c, FALSE);
            for(Database.UpsertResult result : results){
                if(!result.isSuccess()){
                    System.debug(result.getErrors()[0].getMessage());
                }
            }
        } 
    }
    
    @future
    public static void updateRevenueRecords(String recStr){
        toExecute = False;
        List<OA_Revenue_Forecast__c> recToUpdate = (List<OA_Revenue_Forecast__c>)JSON.deserialize(recStr,List<OA_Revenue_Forecast__c>.class);
        update recToUpdate;
    }
    
    public static void beforeInsert(List<Opportunity> newList){
        List<Opportunity> allOppList = [SELECT id, Name, Account.Name, Account_Name_Opportunity_Name__c FROM Opportunity];
        Map<String,Opportunity> allOppMap = new Map<String,Opportunity>();
        for(Opportunity o : allOppList){
            String mainKey = o.AccountId + ' - ' + o.Name;
            allOppMap.put(mainKey,o);
        }
        for(Opportunity opp : newList){
            if(oppRecTypeIdNameMap.get('Change_Request') != opp.RecordTypeId){
                String foreignKey = opp.AccountId + ' - ' + opp.Name; 
                if(allOppMap.containsKey(foreignKey)){
                    opp.addError('This opportunity name already exists under the selected account. Kindly retry by changing the opportunity name or connect with your System Admin for further assistance.');
                }        
            }    
        }
    }
}