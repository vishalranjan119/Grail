public class OA_RegionalSalesQuotaController {
    
    public String yearSelected{get;set;}
    public String regionSelected{get;set;}
    public string salesQuotaId {get;set;}
    public String region{get;set;}
    public Double totalRegionalSQ{get;set;}
    public Double totalRegionalStretchQ{get;set;}
    public Double totalSoldRev{get;set;}
    public Double totalWeightedPipeline{get;set;}
    public Double totalunWeightedPipeline{get;set;}
    public Map<Integer,OA_Monthly_Quota__c> displayMap{get;set;}
    
    public OA_RegionalSalesQuotaController(ApexPages.StandardController controller){
        try{
            Sales_Quota__c temp = (Sales_Quota__c)controller.getRecord();
            salesQuotaId = temp.id;
            Sales_Quota__C sqRec = [SELECT id, OA_CSO__r.Name, OA_CSO__r.Region__c, OA_Region__c, OA_Year__c, OA_Annual_Sales_Quota__c, OA_Annual_Stretch_Quota__c FROM Sales_Quota__c WHERE Id =: temp.id];
            yearSelected = sqRec.OA_Year__c;
            regionSelected = sqRec.OA_Region__c;
            totalRegionalSQ = sqRec.OA_Annual_Sales_Quota__c;
            totalRegionalStretchQ = sqRec.OA_Annual_Stretch_Quota__c;
            totalSoldRev = 0.00;
            totalWeightedPipeline = 0.00;
            totalunWeightedPipeline = 0.00;
            displayMap = new Map<Integer,OA_Monthly_Quota__c>();
            initializeRows();
        }
        Catch(Exception e)
        {
            system.debug(e);
        }
    }
    
    public void initializeRows(){
        Map<Integer,String> monthMap = new Map<Integer,String> {1 => 'January', 2 => 'February', 3 => 'March', 4 => 'April', 5 => 'May', 6 => 'June', 7 => 'July', 8 => 'August', 9 => 'September', 10 => 'October', 11 => 'November', 12 => 'December'};
            List<OA_Monthly_Quota__c> existingMQList = [SELECT id, OA_Month__c, OA_Monthly_Quota__c, OA_Monthly_Stretch_Quota__c FROM OA_Monthly_Quota__c WHERE OA_Sales_Target__c =: salesQuotaId];
        if(!existingMQList.isEmpty()){
            for(OA_Monthly_Quota__c m : existingMQList){
                displayMap.put(Integer.valueOf(m.OA_Month__c),m);
            }
        }
        for(Integer i =1; i< 13;i++){
            OA_Monthly_Quota__c m = new OA_Monthly_Quota__c(OA_Month__c = String.valueOf(i),OA_Sales_Target__c = salesQuotaId);
            if(!displayMap.containsKey(i)){
                displayMap.put(i,m);    
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
    
    public void getAllCalculations(){
        List<User> headOfSelectedRegion = [SELECT id, UserRoleId FROM User WHERE Region__c =: regionSelected]; 
        List<User> agentsOfSelectedRegion = [SELECT id FROM User WHERE UserRoleId =: headOfSelectedRegion[0].UserRoleId];
        for(Sales_Quota__c s : [SELECT id, name, OA_Total_Sold_Revenue__c, OA_Total_Gross_Pipeline__c, OA_Total_Risk_Adjusted_Pipeline__c 
                                FROM Sales_Quota__c WHERE RecordType.DeveloperName = 'Agent_Target' 
                                AND ( OA_CSO__c IN: headOfSelectedRegion OR OA_CSO__c IN: agentsOfSelectedRegion) ]){
                                    System.debug('8888'+s.id+'999'+s.Name);
                                    totalSoldRev = totalSoldRev + s.OA_Total_Sold_Revenue__c;
                                    totalWeightedPipeline = totalWeightedPipeline + s.OA_Total_Risk_Adjusted_Pipeline__c;  
                                    totalunWeightedPipeline = totalunWeightedPipeline + s.OA_Total_Gross_Pipeline__c;  
                                }
    }
}