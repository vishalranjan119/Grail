/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_CreateMilestoneController
Class Purpose: Controller class for Create Milestones page
Versions: 1.1
******************************************************************************************************/
public class OA_CreateMilestoneController {
    
    private Map<Integer, String> monthMap = OA_Utility.getMonthMap();
    private Id oppId;
    public Opportunity currentOpp{get;set;}
    public Map<Integer, MilestoneWrapper> milestones{get;set;}
    public String milestonType{get;set;}
    public Integer currentMonth{get;set;}
    public Integer currentYear{get;set;}
    private Integer rowCount;
    public boolean isValidationFailed{get;set;}
    public boolean displayingEmptyRows{get;set;}
    public boolean isChangeRequest{get;set;}
    public String totalProjectCost{get;set;}
   	private String crOppId;
    public Opportunity crOpp{get;set;}
    public boolean crClosed{get;set;}
    private Set<Id> milestoneAdminIds = new Set<Id>(
        getMilestoneAdmins()
    );
    
    public OA_CreateMilestoneController(ApexPages.StandardController controller){
        Map<String, String> paramMap = ApexPages.currentPage().getParameters();
        if((controller == null || controller.getId() == null) &&  (paramMap == null || !paramMap.containsKey('type'))) return;
        isChangeRequest = false;        
        if(paramMap != null && paramMap.containsKey('type')) isChangeRequest = true;
        oppId = isChangeRequest ? paramMap.get('pid') : controller.getId();
        milestonType = isChangeRequest ?  OA_Constant.INVOICE : OA_Constant.DELIVERY;
        currentOpp = [SELECT id,CurrencyIsoCode,Name,OA_Total_Project_Cost__c, StageName, Amount, Probability FROM Opportunity WHERE Id =: oppId LIMIT 1];        
        currentMonth = SyStem.today().month();
        currentYear =  SyStem.today().year();
        crOppId = isChangeRequest ? paramMap.get('crid') : null;
        if(isChangeRequest){
            crOpp = [Select Amount, Loss_Reason__c ,StageName, Name, OA_CR_Submission_Date__c, Change_Request_Type__c, OA_Change_Request_Amount__c FROM Opportunity WHERE Id =: crOppId];
        }
       
        crClosed = isChangeRequest ? paramMap.get('crs') == OA_Constant.CLOSEDWON  ||  paramMap.get('crs') == 'Closed Lost' : currentOpp.StageName == OA_Constant.CLOSEDWON;
        
        
        if(crClosed) {
            String errorMsg = isChangeRequest ? 'CR is Already '+paramMap.get('crs') : 'Opportunity is Closed won, to make any change create Change Request.';
            OA_Utility.addMessage(errorMsg, 'INFO');
        }
       
        totalProjectCost = isChangeRequest ? String.valueOf(currentOpp.OA_Total_Project_Cost__c + (crClosed ? 0: crOpp.Amount)) : null;
        init();       
    }
    
    
    public void init(){     
        System.debug('milestonType:'+milestonType);        
        isValidationFailed = false;        
        displayingEmptyRows = currentOpp.StageName != OA_Constant.CLOSEDWON ;
        rowCount = currentOpp.StageName != OA_Constant.CLOSEDWON ? 12 : 0;        
        milestones = new Map<Integer, MilestoneWrapper>();
        prepareWrapperMap();
    }
    
    private List<OA_Revenue_Forecast__c> getExistingMilestones(){
        List<OA_Revenue_Forecast__c> oppMilestones = new List<OA_Revenue_Forecast__c>(
            [SELECT Id, CurrencyIsoCode, OA_Comment__c, OA_Opportunity__r.Amount, OA_Invoice_Amount__c, OA_Risk_Adjusted__c , OA_Month__c, OA_Percentage_Invoiced__c, OA_Sales_Revenue__c, OA_Status__c, OA_Year__c
             FROM OA_Revenue_Forecast__c
             WHERE OA_Opportunity__c =: oppId AND RecordType.DeveloperName =: milestonType
            ]
        );		    
        return !oppMilestones.isEmpty() ? oppMilestones : null ;
    }
    
    public void prepareWrapperMap(){
        milestones.putAll(getAdditionalRows());
        //if(currentOpp.StageName != 'Closed Won' ||  milestonType == 'Invoice') milestones.putAll(getAdditionalRows());
        //else {OA_Utility.addMessage('Opportunity is Closed Won. Create chage request to perform any changes with Delivery Milestones. After closing ', 'INFO');}
        List<OA_Revenue_Forecast__c> oppMilestones = getExistingMilestones();
        if(oppMilestones == null) return;
        
        currentOpp.Amount = oppMilestones[0].OA_Opportunity__r.Amount;
        for(OA_Revenue_Forecast__c eachRF : oppMilestones){
            MilestoneWrapper eachRFWrap = new MilestoneWrapper();
            eachRFWrap.month = eachRF.OA_Month__c;
            eachRFWrap.year = eachRF.OA_Year__c;
            eachRFWrap.comment = eachRF.OA_Comment__c;
            eachRFWrap.status = eachRF.OA_Status__c;
            eachRFWrap.sfId = eachRF.Id;
            eachRFWrap.mode = 'v';
            Date cutOffDate = Date.newInstance(
                Integer.valueOf(eachRF.OA_Year__c), 
                Integer.valueOf(eachRF.OA_Month__c)+1, 
                Integer.valueOf(Label.Milestone_Cutoff_Date)
            );
            if(milestonType == OA_Constant.DELIVERY){
                eachRFWrap.riskAdjusted = String.valueOf(eachRF.OA_Risk_Adjusted__c);
                eachRFWrap.revRecognized = String.valueOf(eachRF.OA_Sales_Revenue__c);
            }else if(milestonType == OA_Constant.INVOICE){
                eachRFWrap.percentageInvoioced = String.valueOf(eachRF.OA_Percentage_Invoiced__c != null ? eachRF.OA_Percentage_Invoiced__c.setScale(2) : 0.0);
                eachRFWrap.invoiceAmount =  String.valueOf(eachRF.OA_Invoice_Amount__c);
            }
            eachRFWrap.displayMonthYear = monthMap.get(Integer.valueOf(eachRF.OA_Month__c))+'\''+String.valueOf(eachRF.OA_Year__c).substringAfter('20');
            eachRFWrap.isEditAllowed = eachRFWrap.isDeleteAllowed = TRUE;            
            //if((Integer.valueOf(eachRF.OA_Month__c) < currentMonth &&  Integer.valueOf(eachRF.OA_Year__c) <= currentYear) || crClosed) eachRFWrap.isEditAllowed = eachRFWrap.isDeleteAllowed = FALSE;
            
            if(!milestoneAdminIds.contains(UserInfo.getUserId()) || currentOpp.StageName == OA_Constant.CLOSEDWON || crClosed){
                if(System.today() > cutOffDate || crClosed) eachRFWrap.isEditAllowed = eachRFWrap.isDeleteAllowed = FALSE;
                if(currentOpp.StageName == OA_Constant.CLOSEDWON) eachRFWrap.isDeleteAllowed = FALSE;
            }
            eachRFWrap.mapKey = Integer.valueOf(eachRF.OA_Month__c) + Integer.valueOf(eachRF.OA_Year__c)*100;
            milestones.put(eachRFWrap.mapKey, eachRFWrap);           
        }
    }
    
    
    
    public Map<Integer, MilestoneWrapper> getAdditionalRows(){
       
        Map<Integer, MilestoneWrapper> additionalEmptyRows = new Map<Integer, MilestoneWrapper>();
        String displayMonthYear = '';
        integer tempMonth = milestoneAdminIds.contains(UserInfo.getUserId()) ? 1 : currentMonth;
        integer tempYear = currentYear ;        
        for(Integer i=1; i<=rowCount; i++){            
            if(tempMonth > 12){
                tempMonth = 1;
                tempYear += 1;
            }
            if(!milestones.containsKey(tempMonth+tempYear*100)){ 
                displayMonthYear = monthMap.get(tempMonth)+'\''+String.valueOf(tempYear).substringAfter('20');
                MilestoneWrapper additionalWrap =  new MilestoneWrapper();
                additionalWrap.month = String.valueOf(tempMonth);
                additionalWrap.year = String.valueOf(tempYear);
                additionalWrap.displayMonthYear = displayMonthYear;
                additionalWrap.mode = 'e';
                additionalWrap.isEditAllowed = additionalWrap.isDeleteAllowed = False;
                additionalWrap.status = 'Planned';
                
                additionalEmptyRows.put(tempMonth+tempYear*100, additionalWrap);   
                
            }
            tempMonth ++;
        }         
        System.debug('additionalEmptyRows:'+additionalEmptyRows.size());
        return additionalEmptyRows;
    }
    
    
    public PageReference createMilestones(){
        Decimal milestonesSum = 0;
        String close = ApexPages.currentPage().getParameters().get('close');
        List<OA_Revenue_Forecast__c> revForecastList = new List<OA_Revenue_Forecast__c>();       
        Map<String, String> recordTypeMap = OA_Utility.getRecordTypeInfosByName(OA_Constant.REVENUEFORECASTAPINAME);
        String externalId = '';
        for(MilestoneWrapper eachWrap : milestones.values()){
            if(milestonType ==  OA_Constant.DELIVERY && ! validateDecimalValue(eachWrap.revRecognized)) continue;
            if(milestonType ==  OA_Constant.INVOICE  && ! validateDecimalValue(eachWrap.invoiceAmount)) continue;
            if(isValidationFailed) return null;
            externalId = String.valueOf(oppId)+recordTypeMap.get(milestonType)+eachWrap.month+eachWrap.year;
            OA_Revenue_Forecast__c revForecast = new OA_Revenue_Forecast__c();
            revForecast.OA_Unique_Identifier__c = externalId;
            revForecast.OA_Month__c = eachWrap.month;
            revForecast.OA_Year__c = eachWrap.year;
            revForecast.OA_Comment__c = eachWrap.comment;
            revForecast.RecordTypeId = recordTypeMap.get(milestonType);
            revForecast.OA_Opportunity__c = oppId;
            revForecast.OA_Status__c = eachWrap.status; 
            revForecast.CurrencyIsoCode = currentOpp.CurrencyIsoCode;
            revForecast.OA_Revenue_Flow__c = Integer.valueOf(eachWrap.year) == System.today().year() ? 'C' : Integer.valueOf(eachWrap.year) < System.today().year() ? 'P' : 'F';
            if(milestonType ==  OA_Constant.DELIVERY){
                revForecast.OA_Sales_Revenue__c = Decimal.valueOf(eachWrap.revRecognized);
                milestonesSum += revForecast.OA_Sales_Revenue__c;
            }
            if(milestonType ==  OA_Constant.INVOICE){
                revForecast.OA_Invoice_Amount__c  = Decimal.valueOf(eachWrap.invoiceAmount);
                revForecast.OA_Percentage_Invoiced__c = (revForecast.OA_Invoice_Amount__c*100)/currentOpp.Amount; 
                milestonesSum += revForecast.OA_Invoice_Amount__c;
            }
            revForecastList.add(revForecast);                     
        }
        if(milestonType ==  OA_Constant.INVOICE){
            if(currentOpp.StageName != OA_Constant.CLOSEDWON && milestonesSum > currentOpp.Amount){                
                OA_Utility.addMessage(Label.Invoice_Milestone_Sum_greater_than_100, 'ERROR');
                return null;
            }
            if(!isChangeRequest && currentOpp.StageName == OA_Constant.CLOSEDWON && milestonesSum != currentOpp.OA_Total_Project_Cost__c){
                OA_Utility.addMessage(Label.Invoice_Amount_Opp_Closed_Won_and_Invoice_Milestone_not_equals_to_100, 'ERROR');
                return null;
            }
            if(isChangeRequest && milestonesSum != Decimal.valueOf(totalProjectCost)){
                OA_Utility.addMessage('Invoice amount should be equal to close CR', 'ERROR');
                return null;
            }
        }
        if(milestonType ==  OA_Constant.DELIVERY){
            /*if(milestonesSum > currentOpp.Amount){
                OA_Utility.addMessage(Label.Delivery_Milestone_Sum_greater_than_Opportunity_Amount, 'ERROR');
                return null;
            }*/
            if(currentOpp.StageName == OA_Constant.CLOSEDWON  && milestonesSum <> currentOpp.Amount){
                OA_Utility.addMessage(Label.Delivery_Milestone_Opp_Closed_Won_and_Sum_not_equals_to_Opportunity_Amount, 'ERROR');
                return null;
            }            
        }
        
        
        if(!revForecastList.isEmpty()){
            OA_Utility.handleUpsertResult(
                Database.upsert(revForecastList, Schema.OA_Revenue_Forecast__c.OA_Unique_Identifier__c, FALSE)
            );
        }
        if(isChangeRequest){
            Opportunity crOpp = new Opportunity(Id= crOppId, StageName = 'Closed Won');
            Database.SaveResult sr = Database.update(crOpp);
            if(!sr.isSuccess()) return null;  
            OA_Utility.addMessage('CR closed successfully', 'CONFIRM');
            crClosed = TRUE;
        }
        if(close != null && close != '' && close == 'yes') return renderToOpp();
        
        prepareWrapperMap();
        
        return null;
    }
    
    private boolean validateDecimalValue(String strValue){        
        try{
            Decimal.valueOf(strValue);
            isValidationFailed = false;
            return true; 
        } catch (Exception e) {
            if(strValue != null && strValue != '')
                OA_Utility.addMessage(Label.Valid_Revenue_Recognized_and_Invoiced_Percentage, 'ERROR');
            isValidationFailed = true;
            return FALSE;
        }        
    }
    
    public void enableEditing(){
        MilestoneWrapper m = getMilestoneWrapper();
        if(m == null) return;
        m.mode = 'e';
        m.isEditAllowed = FALSE;    
    }
    
    public void deleteMilestone(){
        MilestoneWrapper m = getMilestoneWrapper();
        if(m == null) return;
        milestones.remove(m.mapKey);
        OA_Revenue_Forecast__c rf = new OA_Revenue_Forecast__c(Id = m.sfId);
        delete rf;
    }
    
    public void rejectCR(){
        if(crOpp.Loss_Reason__c == NULL || crOpp.Loss_Reason__c == '' || crOpp.Loss_Reason__c == '--NONE--'){
            OA_Utility.addMessage('Please Select Loss Reason before Rejecting CR.', 'ERROR');
            return;
        }
        crOpp.StageName = 'Closed Lost';
        crClosed = true;
        OA_Utility.addMessage('CR Rjected Successfully.', 'CONFIRM');
        update crOpp;
        
    }
    
    public void loadMoreRows(){
        rowCount += 6;
        milestones.putAll(getAdditionalRows());
    }
    
    public void togleEmptyRows(){
        milestones.clear();
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
    
    public PageReference renderToOpp(){
        PageReference pageRef = new PageReference('/'+oppId);
        return pageRef;
    }
    
    public MilestoneWrapper getMilestoneWrapper(){
        String key = ApexPages.currentPage().getParameters().get('key');
        if(key == null || key == '' || !key.isNumeric() || !milestones.containsKey(Integer.valueOf(key))){
            OA_Utility.addMessage(Label.Generic_Error_Message, 'FATAL'); 
            return null;
        }       
        return milestones.get(Integer.valueOf(key));        
    }
    
    private set<id> getMilestoneAdmins(){
        Set<Id> milestoneAdminIds = new Set<Id>();       
        for(GroupMember gm : [SELECT Id, UserOrGroupId, Group.Name FROM GroupMember WHERE Group.DeveloperName = 'Milestone_Admin']){
            milestoneAdminIds.add(gm.UserOrGroupId);
        }
        return milestoneAdminIds;
    }

    public class MilestoneWrapper{
        public Id sfId{get;set;}
        public Integer mapKey{get;set;}
        public String month{get;set;}
        public String year{get;set;}
        public boolean isEditAllowed{get;set;}
        public boolean isDeleteAllowed{get;set;}
        public String mode{get;set;}
        public String displayMonthYear{get;set;}
        public String comment{get;set;}
        public String revRecognized{get;set;}
        public String riskAdjusted{get;set;}
        public String status{get;set;}
        public String percentageInvoioced{get;set;}
        public String invoiceAmount{get;set;} 
    }
    
}