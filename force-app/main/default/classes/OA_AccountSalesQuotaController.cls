public class OA_AccountSalesQuotaController {
    
    public String yearSelected{get;set;}
    public string salesQuotaId {get;set;}
    public Double agentSalesQuota{get;set;}
    public Double totalSoldRev{get;set;}
    public Double totalWeightedPipeline{get;set;}
    public Double totalunWeightedPipeline{get;set;}
    public String CSOSelected{get;set;}
    public Map<Integer,OA_Monthly_Quota__c> displayMap{get;set;}
    public String csoName{get;set;}
    public String accName{get;set;}
    public Boolean errOnPage{get;set;}
    public List<Integer> iList{get;set;}
    public Map<Integer,Boolean> renderMap{get;set;}
	public OA_AccountSalesQuotaController(ApexPages.StandardController controller){
        try{
    	Sales_Quota__c temp = (Sales_Quota__c)controller.getRecord();
        salesQuotaId = temp.id;
        Sales_Quota__C sqRec = [SELECT id, OA_Account__r.Name, OA_Account__r.OwnerId, OA_CSO__r.Name, OA_CSO__r.Region__c, OA_Region__c, OA_Year__c, OA_Annual_Sales_Quota__c, OA_Annual_Stretch_Quota__c FROM Sales_Quota__c WHERE Id =: temp.id];
        errOnPage = False;
        CSOSelected = UserInfo.getUserId();
        //validateUser(sqRec);
        yearSelected = sqRec.OA_Year__c;
        csoName = sqRec.OA_CSO__r.Name;
        accName = sqRec.OA_Account__r.Name;
        Sales_Quota__c sqAgentRec = [SELECT id, OA_Annual_Sales_Quota__c, OA_Total_Sold_Revenue__c, OA_Total_Risk_Adjusted_Pipeline__c, OA_Total_Gross_Pipeline__c FROM Sales_Quota__c WHERE RecordType.DeveloperName = 'Agent_Target' AND OA_CSO__c =: CSOSelected AND OA_Year__c =: yearSelected ];
        agentSalesQuota = sqAgentRec.OA_Annual_Sales_Quota__c;
        totalSoldRev = sqAgentRec.OA_Total_Sold_Revenue__c;
		totalWeightedPipeline = sqAgentRec.OA_Total_Risk_Adjusted_Pipeline__c;  
        totalunWeightedPipeline = sqAgentRec.OA_Total_Gross_Pipeline__c;
        displayMap = new Map<Integer,OA_Monthly_Quota__c>();
        forecastRecordsToBeDisplayed();
        initializeRows();
        }
        Catch(Exception e){
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Account Owners Target is not Set'));     
  
        }
    }    
    public void forecastRecordsToBeDisplayed(){
        iList = new List<Integer>();
        if(String.valueOf(Date.today().year()) == yearSelected){
        	iList.add(Date.today().month());
        }    
        if(String.valueOf((Date.today().addMonths(1)).year()) == yearSelected){
        	iList.add((Date.today().addMonths(1)).month());
        }
        if(String.valueOf((Date.today().addMonths(2)).year()) == yearSelected){
        	iList.add((Date.today().addMonths(2)).month());
        }    
    }
    public PageReference validateUser(Sales_Quota__c sq){
        if(sq.OA_Account__r.OwnerId <> CSOSelected){
            errOnPage = TRUE;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You are not authorized to view this record.')); 
        }
        return null;
    }
    public void initializeRows(){
        Map<Integer,String> monthMap = new Map<Integer,String> {1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April', 5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August', 9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'};
        List<OA_Monthly_Quota__c> existingMQList = [SELECT id, OA_Month__c, OA_Monthly_Quota__c, OA_Is_Forecast_Editable__c , OA_Forecast__c, OA_Monthly_Stretch_Quota__c FROM OA_Monthly_Quota__c WHERE OA_Sales_Target__c =: salesQuotaId];
        if(!existingMQList.isEmpty()){
            for(OA_Monthly_Quota__c m : existingMQList){
                //AgentWrapper aw = new AgentWrapper(m,Integer.valueOf(m.OA_Month__c));
                //wrapList.add(aw);
                displayMap.put(Integer.valueOf(m.OA_Month__c),m);
            }
        }
        for(Integer i =1; i< 13;i++){
            OA_Monthly_Quota__c m = new OA_Monthly_Quota__c(OA_Month__c = String.valueOf(i),OA_Sales_Target__c = salesQuotaId);
            //AgentWrapper aw = new AgentWrapper(m,i);
            //wrapList.add(aw);
            if(!displayMap.containsKey(i)){
            	displayMap.put(i,m);    
            }
        }
        
        
        renderMap = new Map<Integer,Boolean>();
        if(displayMap <> null){
        //List<Integer> keyList = new List<Integer>();
        //keyList.addAll(displayMap.keySet());    
            for(Integer i : displayMap.keySet()){
                if(iList.contains(i)){
                    renderMap.put(i,TRUE);
                }
                else{
                    renderMap.put(i,FALSE);
                }
                
                //if(i == Date.today().month() || (i == Date.today().month()))
                //AgentWrapper aw = new AgentWrapper(displayMap.get(i),i);
            	//wrapList.add(aw);
            }
            System.debug('yup'+renderMap);
        }
    }
    
    public PageReference save(){
        List<OA_Monthly_Quota__c> recToUpsert = new List<OA_Monthly_Quota__c>();
        try{
            for(Integer i : displayMap.keySet()){
                if(displayMap.get(i).id == null && displayMap.get(i).OA_Monthly_Quota__c == 0 && displayMap.get(i).OA_Monthly_Stretch_Quota__c == 0 && (displayMap.get(i).OA_Forecast__c == 0 || displayMap.get(i).OA_Forecast__c == null)){
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
        catch(Exception ex){
            if(ex.getMessage().contains('cannot edit forecast on monthly quota')){
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You cannot edit forecast on monthly quota outside three months from today.'));     
            }            
        }
        return null;
    }
    
    public PageReference cancel(){
        PageReference pr = new PageReference('/'+salesQuotaId);
   		pr.setRedirect(true);
        return pr;
    }
    public Class AgentWrapper{
        public OA_Monthly_Quota__c mq{get;set;}
        public Boolean editForecast{get;set;}
        public AgentWrapper(OA_Monthly_Quota__c moQ, Boolean b){
            this.mq =  moQ;
            this.editForecast = b;
        }
    }
}