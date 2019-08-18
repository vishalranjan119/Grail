global class OA_SalesQuotaCalculation implements Database.Batchable<sObject>, Database.Stateful, Schedulable{
    Map<Id, Map<String, String>> csoIdSoldRevMap         = new  Map<Id, Map<String,String>>();
    Map<Id, Map<String, String>> accountIdSoldRevMap     = new  Map<Id, Map<String,String>>();
    Map<Id, Map<String, String>> csoIdPreSoldRevMap      = new  Map<Id, Map<String,String>>();
    Map<Id, Map<String, String>> accountIdPreSoldRevMap  = new  Map<Id, Map<String,String>>();   
    Map<Id, Map<String, String>> csoIdPipelineRevMap     = new  Map<Id, Map<String,String>>();
    Map<Id, Map<String, String>> accountIdPipelineRevMap = new  Map<Id, Map<String,String>>();
    
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String salesQuotaCalculationYear = Label.OA_SalesQuotaCalculationYear;
        String currenYear = '\''+(salesQuotaCalculationYear != null && salesQuotaCalculationYear.isNumeric() ? salesQuotaCalculationYear : String.valueOf(System.today().year()))+'\'';
        String subQueryOppSplit = '(SELECT SplitOwnerId, SplitPercentage FROM OpportunitySplits WHERE SplitType.MasterLabel=\'Revenue\' AND Opportunity.RecordType.DeveloperName = \'Project\')';
        String subQueryRevForecast = '(SELECT OA_Month__c,convertCurrency(OA_Risk_Adjusted__c),convertCurrency(OA_Sales_Revenue__c), convertCurrency(OA_Total_Sales_Revenue_Incl_CRs__c) FROM OA_Revenue_Forecasts__r WHERE RecordType.DeveloperName=\'Delivery\' AND OA_Year__c='+currenYear+')';
        String query = 'SELECT CloseDate, StageName, AccountId,'+subQueryOppSplit+','+subQueryRevForecast+' FROM Opportunity WHERE RecordType.DeveloperName != \'Change_Request\'';       
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Opportunity> scope){         
        List<Opportunity> closedWonOpps = new List<Opportunity>();
        List<Opportunity> pipelineOpps = new List<Opportunity>();
        List<Opportunity> preSoldOpps = new List<Opportunity>();
        String salesQuotaCalculationYear = Label.OA_SalesQuotaCalculationYear;
   
        Integer year = salesQuotaCalculationYear != null && salesQuotaCalculationYear.isNumeric() ? Integer.valueOf(salesQuotaCalculationYear) : System.today().year();
        system.debug(year);
        for(Opportunity opp : scope){
            if(opp.StageName == 'Closed Won' && opp.CloseDate.year() == year) closedWonOpps.add(opp);
            if(opp.StageName == 'Closed Won' && opp.CloseDate.year() == year-1) preSoldOpps.add(opp);
            if(opp.StageName != 'Closed Won' && opp.StageName != 'Closed Lost') pipelineOpps.add(opp);
        }
        System.debug('closedWonOpps:'+closedWonOpps.size());
        if(!closedWonOpps.isEmpty()) prepareMaps(closedWonOpps, 'SOLD');
        if(!pipelineOpps.isEmpty()) prepareMaps(pipelineOpps, 'PIPELINE');        
        if(!pipelineOpps.isEmpty()) prepareMaps(preSoldOpps, 'PRESOLD');
        //prepareSoldRevenueMaps(closedWonOpps);        
    }
    
    public void finish(Database.BatchableContext bc){
        System.debug('1. accountIdPipelineRevMap:'+JSON.serializePretty(accountIdSoldRevMap));
        System.debug('2. csoIdPipelineRevMap:'+JSON.serializePretty(csoIdSoldRevMap));
        //if(csoIdSoldRevMap.isEmpty()) return;
        updateSalesQuota();
        
    }
     
    public void prepareMaps(List<Opportunity> oppList, String rollupType){
        if(oppList == null || oppList.isEmpty()) return;   
        Map<String, String> accountRevenueMap;
        Map<String, String> csoRevenueMap;
        String defaultValue = rollupType.equalsIgnoreCase('PIPELINE') ? '0:0' : '0'; 
        for(Opportunity eachOpp : oppList){

            if(rollupType.equalsIgnoreCase('SOLD') && !accountIdSoldRevMap.containsKey(eachOpp.AccountId)) accountIdSoldRevMap.put(eachOpp.AccountId, new Map<String, String>());
			if(rollupType.equalsIgnoreCase('PRESOLD') && !accountIdPreSoldRevMap.containsKey(eachOpp.AccountId)) accountIdPreSoldRevMap.put(eachOpp.AccountId, new Map<String, String>());
            if(rollupType.equalsIgnoreCase('PIPELINE') && !accountIdPipelineRevMap.containsKey(eachOpp.AccountId)) accountIdPipelineRevMap.put(eachOpp.AccountId, new Map<String, String>());
            accountRevenueMap = rollupType.equalsIgnoreCase('SOLD') ? accountIdSoldRevMap.get(eachOpp.AccountId) : rollupType.equalsIgnoreCase('PIPELINE') ? accountIdPipelineRevMap.get(eachOpp.AccountId) : accountIdPreSoldRevMap.get(eachOpp.AccountId);
                        
            for(OpportunitySplit split : eachOpp.OpportunitySplits){
                
                if(rollupType.equalsIgnoreCase('SOLD') && !csoIdSoldRevMap.containsKey(split.SplitOwnerId)) csoIdSoldRevMap.put(split.SplitOwnerId, new Map<String, String>());
                if(rollupType.equalsIgnoreCase('PRESOLD') && !csoIdPreSoldRevMap.containsKey(split.SplitOwnerId)) csoIdPreSoldRevMap.put(split.SplitOwnerId, new Map<String, String>());
                if(rollupType.equalsIgnoreCase('PIPELINE') && !csoIdPipelineRevMap.containsKey(split.SplitOwnerId)) csoIdPipelineRevMap.put(split.SplitOwnerId, new Map<String, String>());
                csoRevenueMap = rollupType.equalsIgnoreCase('SOLD') ? csoIdSoldRevMap.get(split.SplitOwnerId) : rollupType.equalsIgnoreCase('PIPELINE') ? csoIdPipelineRevMap.get(split.SplitOwnerId) : csoIdPreSoldRevMap.get(split.SplitOwnerId);
                
                
                for(OA_Revenue_Forecast__c revFor : eachOpp.OA_Revenue_Forecasts__r){
					                   
                    if(!csoRevenueMap.containsKey(revFor.OA_Month__c)) csoRevenueMap.put(revFor.OA_Month__c, defaultValue);
                    if(!accountRevenueMap.containsKey(revFor.OA_Month__c)) accountRevenueMap.put(revFor.OA_Month__c, defaultValue);             
                    String csoRev = '';
                    String accRev = '';
                    if(rollupType.equalsIgnoreCase('SOLD') || rollupType.equalsIgnoreCase('PRESOLD')){
                        if(revFor.OA_Total_Sales_Revenue_Incl_CRs__c == null || revFor.OA_Total_Sales_Revenue_Incl_CRs__c == 0) continue;
                        Decimal soldRev_cso = Decimal.valueOf(csoRevenueMap.get(revFor.OA_Month__c)) + ((revFor.OA_Total_Sales_Revenue_Incl_CRs__c * split.SplitPercentage)/100);
                        Decimal soldRev_account = Decimal.valueOf(accountRevenueMap.get(revFor.OA_Month__c)) + revFor.OA_Total_Sales_Revenue_Incl_CRs__c;
                        csoRev = String.valueOf(soldRev_cso);                        
                        accRev = String.valueOf(soldRev_account);
                    }else if(rollupType.equalsIgnoreCase('PIPELINE')){
                        if(revFor.OA_Sales_Revenue__c == null || revFor.OA_Sales_Revenue__c == 0) continue;
                        Decimal csoGrossPipeline = Decimal.valueOf(csoRevenueMap.get(revFor.OA_Month__c).split(':')[0]) + ((revFor.OA_Sales_Revenue__c * split.SplitPercentage)/100);
                        Decimal accGrossPipeline = Decimal.valueOf(accountRevenueMap.get(revFor.OA_Month__c).split(':')[0]) + revFor.OA_Sales_Revenue__c;
                        Decimal csoRiskAdjustedPipeline = Decimal.valueOf(csoRevenueMap.get(revFor.OA_Month__c).split(':')[1]) + ((revFor.OA_Risk_Adjusted__c * split.SplitPercentage)/100);
                        Decimal accRiskAdjustedPipeline = Decimal.valueOf(accountRevenueMap.get(revFor.OA_Month__c).split(':')[1]) + revFor.OA_Risk_Adjusted__c;
                        csoRev = String.valueOf(csoGrossPipeline)+':'+String.valueOf(csoRiskAdjustedPipeline);                        
                        accRev = String.valueOf(accGrossPipeline)+':'+String.valueOf(accRiskAdjustedPipeline); 
                    }
                    csoRevenueMap.put(revFor.OA_Month__c, csoRev); 
                    accountRevenueMap.put(revFor.OA_Month__c, accRev);                     
                }
                if(rollupType.equalsIgnoreCase('SOLD')) csoIdSoldRevMap.put(split.SplitOwnerId, csoRevenueMap);
                else if(rollupType.equalsIgnoreCase('PRESOLD')) csoIdPreSoldRevMap.put(split.SplitOwnerId, csoRevenueMap);
                else csoIdPipelineRevMap.put(split.SplitOwnerId, csoRevenueMap);
            }
            if(rollupType.equalsIgnoreCase('SOLD')) accountIdSoldRevMap.put(eachOpp.AccountId, accountRevenueMap);            
            else if(rollupType.equalsIgnoreCase('PRESOLD')) accountIdPreSoldRevMap.put(eachOpp.AccountId, accountRevenueMap);
            else accountIdPipelineRevMap.put(eachOpp.AccountId, accountRevenueMap);         	            
        }
    }
    
    public void updateSalesQuota(){
        List<OA_Monthly_Quota__c> listToBeUpdated = new List<OA_Monthly_Quota__c>();
        Map<String, String> monthRevMap = new  Map<String, String>();
        Map<String, Decimal> regionolRevMap = new  Map<String, Decimal>();
        Map<Id, OA_Monthly_Quota__c> regionolQuotaMap = new  Map<Id, OA_Monthly_Quota__c>();
       	String salesQuotaCalculationYear = (Label.OA_SalesQuotaCalculationYear != null && Label.OA_SalesQuotaCalculationYear.isNumeric() ? Label.OA_SalesQuotaCalculationYear : String.valueOf(System.today().year()));
        for(OA_Monthly_Quota__c mq : [SELECT Id, OA_Region__c,OA_Sold_Revenue__c, OA_Gross_Pipeline__c, OA_Risk_Adjusted_Pipeline__c, OA_Month__c, OA_Sales_Target__r.OA_Region__c, OA_Sales_Target__r.OA_CSO__r.Region__c, OA_Sales_Target__r.RecordType.DeveloperName, OA_Sales_Target__r.OA_CSO__c, OA_Sales_Target__r.OA_Account__c FROM  OA_Monthly_Quota__c WHERE OA_Sales_Target__r.OA_Year__c =: salesQuotaCalculationYear LIMIT 9999]){            
            
            if(mq.OA_Sales_Target__r.RecordType.DeveloperName == 'Agent_Target'){
                if(csoIdSoldRevMap.containsKey(mq.OA_Sales_Target__r.OA_CSO__c) && 
                   csoIdSoldRevMap.get(mq.OA_Sales_Target__r.OA_CSO__c).containsKey(mq.OA_Month__c))
                {
                     mq.OA_Sold_Revenue__c = Decimal.valueOf(csoIdSoldRevMap.get(mq.OA_Sales_Target__r.OA_CSO__c).get(mq.OA_Month__c));
                }else mq.OA_Sold_Revenue__c = 0.0;
                if(csoIdPreSoldRevMap.containsKey(mq.OA_Sales_Target__r.OA_CSO__c) && 
                   csoIdPreSoldRevMap.get(mq.OA_Sales_Target__r.OA_CSO__c).containsKey(mq.OA_Month__c))
                {
                     mq.OA_Presold_Target_Revenue__c = Decimal.valueOf(csoIdPreSoldRevMap.get(mq.OA_Sales_Target__r.OA_CSO__c).get(mq.OA_Month__c));
                }else mq.OA_Presold_Target_Revenue__c = 0.0;
                if(csoIdPipelineRevMap.containsKey(mq.OA_Sales_Target__r.OA_CSO__c) && 
                   csoIdPipelineRevMap.get(mq.OA_Sales_Target__r.OA_CSO__c).containsKey(mq.OA_Month__c))
                {
                    String pipelineValues = csoIdPipelineRevMap.get(mq.OA_Sales_Target__r.OA_CSO__c).get(mq.OA_Month__c);
                    mq.OA_Gross_Pipeline__c = Decimal.valueOf(pipelineValues.split(':')[0]);
                    mq.OA_Risk_Adjusted_Pipeline__c = Decimal.valueOf(pipelineValues.split(':')[1]);
                }else mq.OA_Gross_Pipeline__c = mq.OA_Risk_Adjusted_Pipeline__c = 0.0;
                if(mq.OA_Sales_Target__r.OA_CSO__r.Region__c != null && mq.OA_Sales_Target__r.OA_CSO__r.Region__c != 'Global'){
                    //System.debug(mq.OA_Sales_Target__c+'-'+mq.OA_Sales_Target__r.OA_CSO__r.Region__c);
                    String key1 = 'SOLD'+mq.OA_Sales_Target__r.OA_CSO__r.Region__c+mq.OA_Month__c;
                    String key2 = 'GP'+mq.OA_Sales_Target__r.OA_CSO__r.Region__c+mq.OA_Month__c;
                    String key3 = 'RAP'+mq.OA_Sales_Target__r.OA_CSO__r.Region__c+mq.OA_Month__c;
                    String key4 = 'PRESOLD'+mq.OA_Sales_Target__r.OA_CSO__r.Region__c+mq.OA_Month__c;
                    if(!regionolRevMap.containsKey(key1)) regionolRevMap.put(key1,0.0);
                    if(!regionolRevMap.containsKey(key2)) regionolRevMap.put(key2,0.0);
                    if(!regionolRevMap.containsKey(key3)) regionolRevMap.put(key3,0.0);
                    if(!regionolRevMap.containsKey(key4)) regionolRevMap.put(key4,0.0);
                    
                    if(mq.OA_Sold_Revenue__c != null) regionolRevMap.put(key1, regionolRevMap.get(key1) + mq.OA_Sold_Revenue__c );
                    if(mq.OA_Gross_Pipeline__c != null) regionolRevMap.put(key2, regionolRevMap.get(key2) + mq.OA_Gross_Pipeline__c);
                    if(mq.OA_Risk_Adjusted_Pipeline__c != null)regionolRevMap.put(key3, regionolRevMap.get(key3) + mq.OA_Risk_Adjusted_Pipeline__c);
                    if(mq.OA_Presold_Target_Revenue__c != null)regionolRevMap.put(key4, regionolRevMap.get(key4) + mq.OA_Presold_Target_Revenue__c);
                }
                listToBeUpdated.add(mq);
                   
                
            }else if(mq.OA_Sales_Target__r.RecordType.DeveloperName == 'Account_Target'){
                if(accountIdSoldRevMap.containsKey(mq.OA_Sales_Target__r.OA_Account__c) && 
                   accountIdSoldRevMap.get(mq.OA_Sales_Target__r.OA_Account__c).containsKey(mq.OA_Month__c))
                {
                    mq.OA_Sold_Revenue__c = Decimal.valueOf(accountIdSoldRevMap.get(mq.OA_Sales_Target__r.OA_Account__c).get(mq.OA_Month__c));
                }else{ 
                    mq.OA_Sold_Revenue__c = 0.0;
                }
                
                //Pre sold
                if(accountIdPreSoldRevMap.containsKey(mq.OA_Sales_Target__r.OA_Account__c) && 
                   accountIdPreSoldRevMap.get(mq.OA_Sales_Target__r.OA_Account__c).containsKey(mq.OA_Month__c))
                {
                    mq.OA_Presold_Target_Revenue__c = Decimal.valueOf(accountIdPreSoldRevMap.get(mq.OA_Sales_Target__r.OA_Account__c).get(mq.OA_Month__c));
                }else{
                    mq.OA_Presold_Target_Revenue__c = 0.0;
                }
                
                //Pipeline
                if(accountIdPipelineRevMap.containsKey(mq.OA_Sales_Target__r.OA_Account__c) && 
                   accountIdPipelineRevMap.get(mq.OA_Sales_Target__r.OA_Account__c).containsKey(mq.OA_Month__c))
                {
                    String pipelineValues = accountIdPipelineRevMap.get(mq.OA_Sales_Target__r.OA_Account__c).get(mq.OA_Month__c);
                    mq.OA_Gross_Pipeline__c = Decimal.valueOf(pipelineValues.split(':')[0]);
                    mq.OA_Risk_Adjusted_Pipeline__c = Decimal.valueOf(pipelineValues.split(':')[1]);
                }else{
                    mq.OA_Gross_Pipeline__c = mq.OA_Risk_Adjusted_Pipeline__c = 0.0;
                }
                listToBeUpdated.add(mq);
                
            }else{
                regionolQuotaMap.put(mq.Id, mq);
            }      
            
        }
        
        for(OA_Monthly_Quota__c mq : regionolQuotaMap.values()){
            
            System.debug('**************************************************');
            String key1 = 'SOLD'+mq.OA_Sales_Target__r.OA_Region__c+mq.OA_Month__c;
            String key2 = 'GP'+mq.OA_Sales_Target__r.OA_Region__c+mq.OA_Month__c;
            String key3 = 'RAP'+mq.OA_Sales_Target__r.OA_Region__c+mq.OA_Month__c;
            String key4 = 'PRESOLD'+mq.OA_Sales_Target__r.OA_Region__c+mq.OA_Month__c;
            System.debug(key1+';'+key2+';'+key3+';'+key4);
            System.debug(regionolRevMap.get(key1)+';'+regionolRevMap.get(key2)+';'+regionolRevMap.get(key3)+';'+regionolRevMap.get(key4));
            if(regionolRevMap.containsKey(key1)){mq.OA_Sold_Revenue__c = regionolRevMap.get(key1);}
            else mq.OA_Sold_Revenue__c = 0.0;
            
            if(regionolRevMap.containsKey(key2)){mq.OA_Gross_Pipeline__c = regionolRevMap.get(key2);}
            else mq.OA_Gross_Pipeline__c = 0.0;  
            
            if(regionolRevMap.containsKey(key3)){mq.OA_Risk_Adjusted_Pipeline__c = regionolRevMap.get(key3);}
            else mq.OA_Risk_Adjusted_Pipeline__c = 0.0;     
            
            if(regionolRevMap.containsKey(key4)){mq.OA_Presold_Target_Revenue__c = regionolRevMap.get(key4);}
            else mq.OA_Presold_Target_Revenue__c = 0.0;    
            
            listToBeUpdated.add(mq);
        }
        
        if(!listToBeUpdated.isEmpty()){
            Database.update(listToBeUpdated, false);
        }
    }
    
    global void execute(SchedulableContext sc){
        OA_SalesQuotaCalculation runBatch = new OA_SalesQuotaCalculation();
        Database.executeBatch(runBatch,200);
    }
    
}