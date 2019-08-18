/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_DisplayMilestoneController
Class Purpose: Controller for Display Milestones Page
Versions: 1.1
******************************************************************************************************/
public without sharing class OA_DisplayMilestoneController { 
    public boolean haveInvoiceMilestone{get;set;}
    public boolean haveDeliveryMilestone{get;set;}
    public List<MilestoneWrapper> deliveryMilestones{get;set;}
    public List<MilestoneWrapper> invoiceMilestones{get;set;}
    public Integer numberOfCR{get;set;}
    
    public OA_DisplayMilestoneController(ApexPages.StandardController controller){
        if(controller == null || controller.getId() == null || controller.getId() == '') return;        
        Id oppId = controller.getId();
        haveInvoiceMilestone = false;
        haveDeliveryMilestone = false;
        numberOfCR = 2;
        setMilestones(oppId);        
    }
    
    private void setMilestones(Id oppId){
        Map<String,MilestoneWrapper> deliveryMilestonesMap = new  Map<String,MilestoneWrapper>();
        Map<Integer, String> monthMap = OA_Utility.getMonthMap();
        deliveryMilestones = new List<MilestoneWrapper>();
        invoiceMilestones = new List<MilestoneWrapper>();
        Map<String, List<OA_Revenue_Forecast__c>> changeRequestMap = new Map<String, List<OA_Revenue_Forecast__c>>();
        for(OA_Revenue_Forecast__c crMilestone : [SELECT id, Name, OA_Opportunity__r.StageName, OA_Opportunity__c, OA_Opportunity__r.OA_Parent_Project__c, RecordTypeId, OA_Month__c, OA_Year__c, OA_Sales_Revenue__c FROM  OA_Revenue_Forecast__c WHERE OA_Opportunity__r.OA_Parent_Project__c =: oppId]){
            String key = String.valueOf(oppId)+
                         String.valueOf(crMilestone.RecordTypeId)+
                    	 crMilestone.OA_Month__c+
                         crMilestone.OA_Year__c;
            if(!changeRequestMap.containsKey(key)) changeRequestMap.put(key, new List<OA_Revenue_Forecast__c>());
            changeRequestMap.get(key).add(crMilestone);   
            
        }
        System.debug('changeRequestMap:'+changeRequestMap);
        for(OA_Revenue_Forecast__c eachMilestone : [SELECT Id, OA_Total_Sales_Revenue_Incl_CRs__c, OA_Unique_Identifier__c, CurrencyIsoCode, OA_Comment__c,OA_Invoice_Amount__c, OA_Month__c,OA_Year__c , OA_Percentage_Invoiced__c, OA_Risk_Adjusted__c,OA_Sales_Revenue__c,OA_Status__c, RecordType.DeveloperName, RecordType.Name FROM OA_Revenue_Forecast__c WHERE OA_Opportunity__c=: oppId Order by OA_Year__c, OA_Month__c]){
            if(eachMilestone.RecordType.Name == null || eachMilestone.OA_Month__c == null || eachMilestone.OA_Year__c == null) continue;
            MilestoneWrapper milestoneWrapper = new MilestoneWrapper();
            milestoneWrapper.sfId = eachMilestone.Id;
            milestoneWrapper.comment = eachMilestone.OA_Comment__c;
            milestoneWrapper.status = eachMilestone.OA_Status__c;
            milestoneWrapper.currencyType = eachMilestone.CurrencyIsoCode;
            milestoneWrapper.displayMonthYear = monthMap.get(Integer.valueOf(eachMilestone.OA_Month__c))+'\''+String.valueOf(eachMilestone.OA_Year__c).substringAfter('20');
            
            if(eachMilestone.RecordType.DeveloperName.equalsIgnoreCase(OA_Constant.DELIVERY)){
                milestoneWrapper.salesRevenue =  eachMilestone.OA_Sales_Revenue__c;
                milestoneWrapper.totalSalesRevenue =  eachMilestone.OA_Total_Sales_Revenue_Incl_CRs__c;
                milestoneWrapper.riskAdjusted = eachMilestone.OA_Risk_Adjusted__c;
                if(changeRequestMap.containsKey(eachMilestone.OA_Unique_Identifier__c)){
                    List<String> tempList = new List<String>();
                    milestoneWrapper.changeRequests = new List<ChangeWrapper>(); 
                    for(OA_Revenue_Forecast__c crm : changeRequestMap.get(eachMilestone.OA_Unique_Identifier__c)){
                        ChangeWrapper change = new ChangeWrapper();
                        change.crOppId = crm.OA_Opportunity__c;
                        change.crMilestoneId = crm.Id;
                        change.changeAmount = crm.OA_Sales_Revenue__c;
                        change.isClosed = crm.OA_Opportunity__r.StageName == OA_Constant.CLOSEDWON;
                        milestoneWrapper.changeRequests.add(change);
                        tempList.add(String.valueOf(crm.OA_Sales_Revenue__c));
                    }
                    milestoneWrapper.changeAmounts = String.join(tempList, ','); 
                }
                deliveryMilestones.add(milestoneWrapper);
            }else if(eachMilestone.RecordType.DeveloperName.equalsIgnoreCase(OA_Constant.INVOICE)){
                milestoneWrapper.percentageInvoioced = eachMilestone.OA_Percentage_Invoiced__c != null ? eachMilestone.OA_Percentage_Invoiced__c.setScale(2) : 0.0;
                milestoneWrapper.invoiceAmount = eachMilestone.OA_Invoice_Amount__c;
                invoiceMilestones.add(milestoneWrapper);
            }                
        }
        if(deliveryMilestones.size() > 0) haveDeliveryMilestone = true;
        if(invoiceMilestones.size() > 0)  haveInvoiceMilestone = true; 

    }
    
    public class MilestoneWrapper{
        public String sfId{get;set;}
        public String displayMonthYear{get;set;}
        public String comment{get;set;}
        public Decimal salesRevenue{get;set;}
        public Decimal totalSalesRevenue{get;set;}
        public Decimal riskAdjusted{get;set;}
        public String status{get;set;}
        public Decimal percentageInvoioced{get;set;}
        public Decimal invoiceAmount{get;set;}
        public String currencyType{get;set;}
        public String changeAmounts{get;set;}
        public List<ChangeWrapper> changeRequests{get;set;}
    }
    
    public class ChangeWrapper{
        public Id crOppId{get;set;}
        public Id crMilestoneId{get;set;}
        public boolean isClosed{get;set;}
        public String name{get;set;}
        public Decimal changeAmount{get;set;}
    }
}