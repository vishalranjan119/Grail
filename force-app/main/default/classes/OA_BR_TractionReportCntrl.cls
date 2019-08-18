public class OA_BR_TractionReportCntrl {
    public String selectedYear{get;set;}
    public String selectedMonth{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<AggregateResult> sold_results{get;set;}
    public List<ReportsTableWrapper> wrapperList{get;set;}
    public OA_Data_Snapshots__c revenueRecord{get;set;}
    List<AggregateResult> pipeline_results{get;set;}
    public Boolean displaySearch{get;set;}
    
    public OA_BR_TractionReportCntrl(){
        years = OA_ReportUtility.getYearList();
        months = OA_ReportUtility.getMonthList();
        selectedMonth  = String.valueOf(System.today().month()-1); //'12';
        selectedYear   = String.valueOf(System.today().year()); //'2017';
        search();
    }
    
    public PageReference search(){ 
        revenueRecord = new OA_Data_Snapshots__c();
        ReportsTableWrapper reportData;
        wrapperList = new List<ReportsTableWrapper>();
        Map<String,ReportsTableWrapper> wrapperMap = new Map<String,ReportsTableWrapper>();
        try{
        sold_results = [Select OA_Region__c reg, SUM(Gross__c) totalSold 
                        FROM OA_Data_Snapshots__c 
                        WHERE OA_Year__c=: selectedYear 
                        AND Snapshot_Month__c =: selectedMonth 
                        AND OA_Probability__c = 100 GROUP BY RollUp(OA_Region__c)];
        
        pipeline_results = [Select OA_Region__c reg, SUM(Risk_Adjusted__c) risk
                            FROM OA_Data_Snapshots__c 
                            WHERE OA_Year__c=: selectedYear 
                            AND Snapshot_Month__c =: selectedMonth 
                            AND OA_Probability__c < 100 GROUP BY RollUp(OA_Region__c)];
        
        /*salesQuota_results = [SELECT SUM(OA_Annual_Sales_Quota__c) total, OA_Region__c reg  
                              FROM Sales_Quota__c 
                              WHERE OA_Year__c =: selectedYear
                              AND RecordType.DeveloperName = 'Regional_Target' GROUP BY RollUp(OA_Region__c)];*/
        List<AggregateResult> budget_results = [SELECT SUM(OA_Total_Budget__c) total, OA_Region__c reg  
                                                    FROM OA_Budget__c 
                                                    WHERE OA_Year__c =: selectedYear
                                                    GROUP BY RollUp(OA_Region__c)];
        
        for(AggregateResult agr : sold_results){
            if(agr.get('reg') != null){
                reportData = new ReportsTableWrapper(String.valueOf(agr.get('reg')),selectedMonth,selectedYear,(Double)agr.get('totalSold'));
                wrapperMap.put(String.valueOf(agr.get('reg')),reportData);
            }
            else if(agr.get('reg') == null){
                reportData = new ReportsTableWrapper('Global',selectedMonth,selectedYear,(Double)agr.get('totalSold'));
                wrapperMap.put('Global',reportData);
            }
        }
            
        for(AggregateResult agr : pipeline_results){
            if(null != agr.get('reg')){
                wrapperMap.get(String.valueOf(agr.get('reg'))).Weighted_Pipeline = (Double)agr.get('risk');
            }
            else if(agr.get('reg') == null){
                wrapperMap.get('Global').Weighted_Pipeline = (Double)agr.get('risk');
            }
        }
        Double totalSalesQuota = 0.00;
        for(AggregateResult sq : budget_results){
            if(sq.get('reg') == null){
                wrapperMap.get('Global').Budget = (((Decimal)sq.get('total'))/1000).setScale(2);
            }
            else if(sq.get('reg') != null && wrapperMap.containsKey(String.valueOf(sq.get('reg')))){
                wrapperMap.get(String.valueOf(sq.get('reg'))).Budget = (((Decimal)sq.get('total'))/1000).setScale(2);
            }   
        }
        for(ReportsTableWrapper rep : wrapperMap.values()){    
            if(rep.Sold > rep.Budget){
                rep.Surplus = (rep.Sold - rep.Budget).setScale(1);
                rep.SurplusPercent = ((rep.Surplus/rep.Budget)*100).setScale(1);
                rep.SoldPercent = 100;                
                rep.yetToBeIdentfied = 0.0;
                rep.yetToBeIdentfiedPerCent = 0.0;
            }
            else{
                rep.Surplus = 0.0;
                rep.SurplusPercent = 0.0;               
                rep.SoldPercent = ((rep.Sold/rep.Budget)*100).setScale(1);
                rep.yetToBeIdentfied = rep.Budget - rep.Sold - rep.Surplus - rep.Weighted_Pipeline;                
                rep.yetToBeIdentfiedPerCent = ((rep.yetToBeIdentfied/rep.Budget)*100).setScale(1);
                if(rep.yetToBeIdentfied < 0) rep.yetToBeIdentfiedPerCent = rep.yetToBeIdentfied = 0.0;
            }   
            if(rep.Sold > rep.Budget){
                rep.Sold = rep.Budget;       
            }
            rep.TotalSoldPercent = ((rep.TotalSold/rep.Budget)*100).setScale(1);
            rep.SoldplusPipeline= rep.Sold + rep.Weighted_Pipeline;
            rep.SoldPipelinePercent= ((rep.SoldplusPipeline/rep.Budget)*100).setScale(1);  
            rep.PipelinePerCent = ((rep.Weighted_Pipeline/rep.Budget)*100).setScale(1);            
            wrapperList.add(rep);
        }   
        //data d = new data(sqRecord.OA_Region__c, sqRecord.Total_Sold_millions__c, sqRecord.Total_Risk_Adjusted_Pipeline_millions__c ,sqRecord.Budget_millions__c, sqRecord.Surplus_millions__c, sqRecord.OA_Gap__c);
        //dataList.add(d);
        }
        catch(Exception e){
          
            System.debug('Error:'+e.getMessage() + e.getStackTraceString());
            OA_Utility.addMessage('Data not found in the system for selected year.', 'Info');
        }
        return null;
    }
    

    public class ReportsTableWrapper{
        public String Region{get;set;}
        public String Month{get;set;}
        public String Year{get;set;}
        public Decimal Sold {get;set;}
        public Decimal TotalSold {get;set;}
        public Decimal TotalSoldPercent {get;set;}
        public Decimal Weighted_Pipeline{get;set;}  
        public Decimal SoldplusPipeline{get;set;}  
        public Decimal Budget {get;set;}   
        public Decimal Surplus {get;set;}   
        public Decimal SurplusPercent {get;set;}   
        public Decimal SoldPercent{get;set;}
        public Decimal SoldPipelinePercent{get;set;}
        public Decimal PipelinePerCent{get;set;}
        public Decimal yetToBeIdentfied{get;set;}
        public Decimal yetToBeIdentfiedPerCent{get;set;}
        public ReportsTableWrapper(String reg, String mon, String year, Decimal totalSold){
            this.Region = reg;
            this.Month = mon;
            this.Year = year;
            this.Sold = (totalSold/1000).setScale(2);
            this.TotalSold = (totalSold/1000).setScale(2);
            /*this.Weighted_Pipeline = Weighted_Pipeline;
            this.Budget = (Budget/1000).setScale(2);
            if(this.Sold > this.Budget) Surplus = ((Sold - Budget)/1000).setScale(2);
            else Gap = ((Budget - Sold)/1000).setScale(2);*/
        }
    }
}