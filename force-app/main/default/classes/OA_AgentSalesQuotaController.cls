public class OA_AgentSalesQuotaController {
	
    public String yearSelected{get;set;}
    public string salesQuotaId {get;set;}
    public String region{get;set;}
    public Double regionalSalesQuota{get;set;}
    public Double totalSoldRev{get;set;}
    public Double totalWeightedPipeline{get;set;}
    public Double totalunWeightedPipeline{get;set;}
    public List<OA_Monthly_Quota__c> mqList{get;set;}
    public List<OA_Monthly_Quota__c> recToDeleteList{get;set;}
    public String removeRowId{get;set;}
    public String removeRowNum{get;set;}
    public String CSOSelected{get;set;}
    public List<AgentWrapper> wrapList{get;set;}
    public Map<Integer,OA_Monthly_Quota__c> displayMap{get;set;}
    
    public OA_AgentSalesQuotaController(ApexPages.StandardController controller){
        try{
    	Sales_Quota__c temp = (Sales_Quota__c)controller.getRecord();
        salesQuotaId = temp.id;
        Sales_Quota__C sqRec = [SELECT id, OA_CSO__r.Name, OA_CSO__r.Region__c, OA_Region__c, OA_Year__c, OA_Annual_Sales_Quota__c, OA_Annual_Stretch_Quota__c FROM Sales_Quota__c WHERE Id =: temp.id];
        yearSelected = sqRec.OA_Year__c;
        CSOSelected = sqRec.OA_CSO__r.Name;
        region = sqRec.OA_CSO__r.Region__c;
        Sales_Quota__c sqRegionRec = [SELECT id, OA_Annual_Sales_Quota__c, OA_Total_Sold_Revenue__c, OA_Total_Risk_Adjusted_Pipeline__c, OA_Total_Gross_Pipeline__c FROM Sales_Quota__c WHERE RecordType.DeveloperName = 'Regional_Target' AND  OA_Region__c =: region AND OA_Year__c =: yearSelected ];
        regionalSalesQuota = sqRegionRec.OA_Annual_Sales_Quota__c;
        totalSoldRev = sqRegionRec.OA_Total_Sold_Revenue__c;
		totalWeightedPipeline = sqRegionRec.OA_Total_Risk_Adjusted_Pipeline__c;  
        totalunWeightedPipeline = sqRegionRec.OA_Total_Gross_Pipeline__c;  
        wrapList = new List<AgentWrapper>();
        displayMap = new Map<Integer,OA_Monthly_Quota__c>();
            initializeRows();}
        Catch(Exception e){
            System.debug(e);
        }
    }
    
    public void initializeRows(){
        Map<Integer,String> monthMap = new Map<Integer,String> {1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April', 5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August', 9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'};
        List<OA_Monthly_Quota__c> existingMQList = [SELECT id, OA_Month__c, OA_Monthly_Quota__c, OA_Monthly_Stretch_Quota__c FROM OA_Monthly_Quota__c WHERE OA_Sales_Target__c =: salesQuotaId];
        if(!existingMQList.isEmpty()){
            for(OA_Monthly_Quota__c m : existingMQList){
                AgentWrapper aw = new AgentWrapper(m,Integer.valueOf(m.OA_Month__c));
                //wrapList.add(aw);
                displayMap.put(Integer.valueOf(m.OA_Month__c),m);
            }
        }
        for(Integer i =1; i< 13;i++){
            OA_Monthly_Quota__c m = new OA_Monthly_Quota__c(OA_Month__c = String.valueOf(i),OA_Sales_Target__c = salesQuotaId);
            AgentWrapper aw = new AgentWrapper(m,i);
            //wrapList.add(aw);
            if(!displayMap.containsKey(i)){
            	displayMap.put(i,m);    
            }
        }
        
        if(displayMap <> null){
        List<Integer> keyList = new List<Integer>();
        keyList.addAll(displayMap.keySet());    
            for(Integer i : keyList){
                AgentWrapper aw = new AgentWrapper(displayMap.get(i),i);
            	wrapList.add(aw);
            }
        }
    }
    
    public PageReference save(){
        List<OA_Monthly_Quota__c> recToUpsert = new List<OA_Monthly_Quota__c>();
        for(Integer i : displayMap.keySet()){
            if(displayMap.get(i).id == null && displayMap.get(i).OA_Monthly_Quota__c == 0 && displayMap.get(i).OA_Monthly_Stretch_Quota__c == 0){
            	continue;
            }    
            else{
                recToUpsert.add(displayMap.get(i));
            }
        }      
        upsert recToUpsert;
        PageReference pr = new PageReference('/'+salesQuotaId);
   		pr.setRedirect(true);
        return pr;
    }
    
    public PageReference cancel(){
        PageReference pr = new PageReference('/'+salesQuotaId);
   		pr.setRedirect(true);
        return pr;
    }
    
    public Class AgentWrapper{
        public OA_Monthly_Quota__c mq{get;set;}
        public Integer index{get;set;}
        public AgentWrapper(OA_Monthly_Quota__c moQ, Integer i){
            this.mq =  moQ;
            this.index = i;
        }
    }
}