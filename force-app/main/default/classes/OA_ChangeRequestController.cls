public class OA_ChangeRequestController {
	Map<String, String> recordTypeMap = OA_Utility.getRecordTypeInfosByName(OA_Constant.REVENUEFORECASTAPINAME);    
    private Map<Integer, String> monthMap = OA_Utility.getMonthMap();
    private Map<Integer, ChangeRequestWrapper> emptyRows;
    public Opportunity parentOpp{get;set;}
    public Map<Integer, ChangeRequestWrapper> changeRequests{get;set;} 
    private Id oppId;
    public boolean displayingEmptyRows{get;set;}
    public boolean oppClosedWon{get;set;}
    public Opportunity crOpp{get;set;}
    integer rowCount = 0;
    
    public OA_ChangeRequestController(ApexPages.StandardController controller){
        if(controller == null || controller.getId() == null || String.valueOf(controller.getId()) == '') return;
        oppId = controller.getId();
        displayingEmptyRows = false;
        oppClosedWon = true;
        parentOpp = getParentOpp();
        if(!validate()) return;
       	crOpp = parentOpp.ChangeRequest__r != null &&  !parentOpp.ChangeRequest__r.isEmpty() ?  parentOpp.ChangeRequest__r[0] : initCROpp();
        
        prepareWrapperMap();
    }
    
    public Opportunity getParentOpp(){
        return [SELECT id, StageName, Name, CloseDate, Amount,CurrencyIsoCode,
                (Select Id,OA_Sales_Revenue__c,OA_Total_Sales_Revenue_Incl_CRs__c,OA_Month__c,OA_Year__c FROM OA_Revenue_Forecasts__r WHERE RecordType.DeveloperName =: OA_Constant.DELIVERY), 
                (SELECT Id, Amount ,Name, Change_Request_Type__c, CloseDate, OA_CR_Submission_Date__c, OA_Change_Request_Amount__c, StageName FROM ChangeRequest__r WHERE StageName != : OA_Constant.CLOSEDWON AND StageName !=  'Closed Lost' LIMIT 1) 
                FROM Opportunity WHERE Id =: oppId LIMIT 1
               ];
    }
    
    @testVisible
    private Opportunity initCROpp(){
        Opportunity crOpp = new Opportunity(
            Name = parentOpp.Name+'__CR',
            Change_Request_Type__c =  'Scope Change',
            StageName = 'Proposal',
            CloseDate = parentOpp.CloseDate,
            OA_CR_Submission_Date__c =  System.today(),
            OA_Parent_Project__c = parentOpp.Id,
            RecordTypeId = OA_Utility.getRecordTypeInfosByName('Opportunity').get('Change_Request'),
            CurrencyIsoCode = parentOpp.CurrencyIsoCode           
        );   
        return crOpp;
    }
    
    public PageReference renderToOpp(){
        PageReference pageRef = new PageReference('/'+oppId);
        return pageRef;
    }
    
    private boolean validate(){
        boolean isSuccess = true;
        if(parentOpp.StageName != OA_Constant.CLOSEDWON){
            OA_Utility.addMessage('Change Requests are only captured for Closed won Opportunity ', 'INFO');
            isSuccess = false;
            oppClosedWon = false;
        }
        return isSuccess;
    }
    
    public void prepareWrapperMap(){
        Map<Integer, OA_Revenue_Forecast__c> parentMilestones = new Map<Integer, OA_Revenue_Forecast__c>();
        Map<Integer, OA_Revenue_Forecast__c> crMilestones = new Map<Integer, OA_Revenue_Forecast__c> ();
        Integer currentMonth = SyStem.today().month();
        Integer currentYear =  SyStem.today().year();
        changeRequests = new Map<Integer, ChangeRequestWrapper>();
        Set<Id> crOppIds = new Set<Id>();
        Integer mapKey = 0;
        for(OA_Revenue_Forecast__c parRevFor : parentOpp.OA_Revenue_Forecasts__r){
            mapKey = Integer.valueOf(parRevFor.OA_Month__c) + Integer.valueOf(parRevFor.OA_Year__c)*100;
            parentMilestones.put(mapKey, parRevFor);
        }        
        for(OA_Revenue_Forecast__c crRevFor : [SELECT Id,OA_Opportunity__c, OA_Sales_Revenue__c,OA_Total_Sales_Revenue_Incl_CRs__c,OA_Month__c,OA_Year__c FROM OA_Revenue_Forecast__c WHERE RecordType.DeveloperName =: OA_Constant.DELIVERY AND OA_Opportunity__c IN : parentOpp.ChangeRequest__r]){
            mapKey = Integer.valueOf(crRevFor.OA_Month__c) + Integer.valueOf(crRevFor.OA_Year__c)*100;
            crMilestones.put(mapKey, crRevFor);
        }
        Set<Integer> mapKeys = new Set<Integer>();
        mapKeys.addAll(parentMilestones.keyset());
        mapKeys.addAll(crMilestones.keyset());
        OA_Revenue_Forecast__c revForecast = new OA_Revenue_Forecast__c();
        for(Integer key : mapKeys){
            ChangeRequestWrapper changeRequest = new ChangeRequestWrapper();
             changeRequest.isEditAllowed = TRUE;
            if(parentMilestones.containsKey(key)){
                revForecast = parentMilestones.get(key);
                changeRequest.month = revForecast.OA_Month__c;
                changeRequest.year = revForecast.OA_Year__c;
                changeRequest.displayMonthYear = monthMap.get(Integer.valueOf(revForecast.OA_Month__c))+'\''+String.valueOf(revForecast.OA_Year__c).substringAfter('20');
                changeRequest.parentSalesRev = String.valueOf(revForecast.OA_Sales_Revenue__c);
                changeRequest.parentSalesRevIncCR = String.valueOf(revForecast.OA_Total_Sales_Revenue_Incl_CRs__c);                
            }
            if(crMilestones.containsKey(key)){
                revForecast = crMilestones.get(key);
                changeRequest.crOppId = revForecast.OA_Opportunity__c;
                changeRequest.month = revForecast.OA_Month__c;
                changeRequest.year = revForecast.OA_Year__c;
                changeRequest.displayMonthYear = monthMap.get(Integer.valueOf(revForecast.OA_Month__c))+'\''+String.valueOf(revForecast.OA_Year__c).substringAfter('20');
                changeRequest.changeAmount = String.valueOf(revForecast.OA_Sales_Revenue__c);
            }
            Date cutOffDate = Date.newInstance(
                Integer.valueOf(revForecast.OA_Year__c), 
                Integer.valueOf(revForecast.OA_Month__c)+1, 
                Integer.valueOf(Label.Milestone_Cutoff_Date)
            );
            /*if(Integer.valueOf(revForecast.OA_Month__c) < currentMonth &&  Integer.valueOf(revForecast.OA_Year__c) <= currentYear){
                changeRequest.isEditAllowed = FALSE;
            } */
            if(System.today() > cutOffDate) changeRequest.isEditAllowed = FALSE;
            changeRequests.put(key, changeRequest);
        }
        if(!displayingEmptyRows) return;
        changeRequests.putAll(getAdditionalRows());
    }
    
    boolean allOK;
    public PageReference createChangeRequest(){
        allOK = true;
        Id crOppId;
        try{            
            String close = ApexPages.currentPage().getParameters().get('close');
            if(parentOpp.ChangeRequest__r == null || parentOpp.ChangeRequest__r.isEmpty()){                
                Database.SaveResult sr = Database.insert(crOpp);
                if(!sr.isSuccess()){
                    OA_Utility.addMessage(JSON.serializePretty(sr.getErrors()), 'ERROR');
                    return null;
                }
                crOppId = sr.getId();
            }else{ 
                crOppId = parentOpp.ChangeRequest__r[0].Id;
                Database.update(crOpp);
            }
            List<OA_Revenue_Forecast__c> crList = new List<OA_Revenue_Forecast__c>();
            
            String externalId = '';
            for(ChangeRequestWrapper changeRequest : changeRequests.values()){
                OA_Revenue_Forecast__c cr = new OA_Revenue_Forecast__c();
                if(changeRequest.changeAmount == null || changeRequest.changeAmount == '' || !validateDecimalValue(changeRequest.changeAmount)) {continue;}            
                if(changeRequest.parentSalesRevIncCR == null || changeRequest.parentSalesRevIncCR == '') changeRequest.parentSalesRevIncCR = '0';
                if(Decimal.valueOf(changeRequest.parentSalesRevIncCR) + Decimal.valueOf(changeRequest.changeAmount) < 0){
                    OA_Utility.addMessage('Please input valid decimal value - '+ changeRequest.displayMonthYear+' Max Allowed - '+changeRequest.parentSalesRevIncCR, 'ERROR');
                    allOK = false;
                }
                externalId = String.valueOf(crOppId)+recordTypeMap.get(OA_Constant.DELIVERY)+changeRequest.month+changeRequest.year;
                cr.OA_Opportunity__c = crOppId;
                cr.OA_Month__c = changeRequest.month;
                cr.OA_Year__c  = changeRequest.year;
                cr.OA_Sales_Revenue__c = Decimal.valueOf(changeRequest.changeAmount);
                cr.RecordTypeId = recordTypeMap.get(OA_Constant.DELIVERY);
                cr.OA_Unique_Identifier__c = externalId;
                cr.CurrencyIsoCode = parentOpp.CurrencyIsoCode;
                crList.add(cr);
            }
            System.debug(' crList:'+ crList);
            if(!crList.isEmpty() && allOK){            
                Map<Integer, String> errorMap = OA_Utility.handleUpsertResult(
                    Database.upsert(crList, Schema.OA_Revenue_Forecast__c.OA_Unique_Identifier__c, FALSE)
                );
                if(errorMap.isEmpty()) OA_Utility.addMessage('Change Request captured successfully.', 'CONFIRM');
                else{
                    for(Integer index : errorMap.keySet()){
                        OA_Utility.addMessage(errorMap.get(index), 'ERROR');
                        allOK = false;
                    }
                }
            }
            if(allOK && close != null && close != '' && close == 'yes') return renderToOpp();
            parentOpp = getParentOpp(); //querying parent opp again, it is needed because when user click save button second time it will check the CR created in first time or not. it prevent multiple creation of CR in proposal stage.
            crOpp = parentOpp.ChangeRequest__r[0];
        }Catch(Exception e){
           	System.debug('Error:'+e.getMessage() + e.getStackTraceString());
            OA_Utility.addMessage(e.getMessage(), 'ERROR');
        }
        
        return null;
    }
    
    private boolean validateDecimalValue(String strValue){        
        try{
            Decimal.valueOf(strValue);           
            return true; 
        } catch (Exception e) {
            if(strValue != null && strValue != '')
                OA_Utility.addMessage(Label.Valid_Revenue_Recognized_and_Invoiced_Percentage, 'ERROR');
			allOK = false;            
            return FALSE;
        }        
    }
    
    
    public void togleEmptyRows(){
        changeRequests.clear();
        if(displayingEmptyRows){
            displayingEmptyRows = false;
            rowCount = 0;
        }
        else {
            displayingEmptyRows = true;
            rowCount = 12;
        }
        prepareWrapperMap();
    }
    
     public void loadMoreRows(){
        rowCount += 6;
        changeRequests.putAll(getAdditionalRows());
    }
    
    public Map<Integer, ChangeRequestWrapper> getAdditionalRows(){
        System.debug('rowCount:'+rowCount);
        Map<Integer, ChangeRequestWrapper> additionalEmptyRows = new Map<Integer, ChangeRequestWrapper>();
        String displayMonthYear = '';
        integer tempMonth = System.today().month();
        integer tempYear = System.today().year();        
        for(Integer i=1; i<=rowCount; i++){            
            if(tempMonth > 12){
                tempMonth = 1;
                tempYear += 1;
            }
            if(!changeRequests.containsKey(tempMonth+tempYear*100)){ 
                displayMonthYear = monthMap.get(tempMonth)+'\''+String.valueOf(tempYear).substringAfter('20');
                ChangeRequestWrapper additionalWrap =  new ChangeRequestWrapper();
                additionalWrap.month = String.valueOf(tempMonth);
                additionalWrap.year = String.valueOf(tempYear);
                additionalWrap.displayMonthYear = displayMonthYear;                
                additionalWrap.isEditAllowed = true;
                additionalWrap.parentSalesRev = '0';
                additionalWrap.parentSalesRevIncCR = '0';
                additionalEmptyRows.put(tempMonth+tempYear*100, additionalWrap);                   
            }
            tempMonth ++;
        }         
        System.debug('additionalEmptyRows:'+additionalEmptyRows.size());
        return additionalEmptyRows;
    }
    
   
    
    
    public class ChangeRequestWrapper{
        private Id crOppId;
        public Id parentSFId;
        public Id crSFId;
        public String month;
        public String year;        
        public String displayMonthYear{get;set;}
        public String comment{get;set;}
        public boolean isEditAllowed{get;set;}
        public String parentSalesRev{get;set;}
        public String parentSalesRevIncCR{get;set;}
        public String changeAmount{get;set;}
        public String total{get;set;}
    }
    
}