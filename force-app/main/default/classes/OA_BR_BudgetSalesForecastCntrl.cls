public class OA_BR_BudgetSalesForecastCntrl {  
    Set<String> monthSet = new Set<String>();    
    Map<String, String> monthMap = OA_ReportUtility.getMonthMap();
    public List<ReportData> dataList{get;set;}
    public String selectedYear{get;set;}
    public String selectedMonth{get;set;}
    public String snapshotMonth{get;set;}
    public String selectedRegion{get;set;}
    public List<SelectOption> years{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> regionList{get;set;}
    
    public OA_BR_BudgetSalesForecastCntrl(){
        
        years = OA_ReportUtility.getYearList();
        months = OA_ReportUtility.getMonthList();
        selectedRegion = 'Global';
        selectedMonth = String.valueOf(Date.today().month());
        snapshotMonth = String.valueOf(Date.today().month()-1);
        selectedYear = String.valueOf(Date.today().year());
        regionList = OA_ReportUtility.getRegionList();
        
        
        reportTableData();
    }   
    
  
    
    public void reportTableData(){ 
        dataList = new List<ReportData>();               
        Map<String,Map<String, Decimal>> budgetMap = new Map<String,Map<String, Decimal>>();
        Map<String,Map<String, Decimal>> forecastMap = new Map<String,Map<String, Decimal>>();
        Map<String,Map<String, Decimal>> soldMap = new Map<String,Map<String, Decimal>>();
        Map<String,Map<String, Decimal>> pipelineMap = new Map<String,Map<String, Decimal>>();
        String key = '';
        try{
            Set<String> regionSet = new Set<String>{selectedRegion};            
            if(selectedRegion == 'Global'){
                for(SelectOption region : regionList){
                    regionSet.add(region.getValue());
                }
            }
            if(Integer.valueOf(selectedYear) == System.today().year() &&
               (Integer.valueOf(snapshotMonth) > System.today().month() ))
            {
                OA_Utility.addMessage('Snapshot month must not be greater than the current month for year: '+selectedYear, 'Info');
                return;
            }
            budgetMap = OA_ReportUtility.getRegionlQuotaByMonth(selectedYear);
            monthSet = new Set<String>();
            if(Integer.valueOf(snapshotMonth) <= 12) monthSet.add(String.valueOf(Integer.valueOf(snapshotMonth)));
            
            if(Integer.valueOf(snapshotMonth)+1 <= 12) monthSet.add(String.valueOf(Integer.valueOf(snapshotMonth)+1));
            if(Integer.valueOf(snapshotMonth)+2 <= 12) monthSet.add(String.valueOf(Integer.valueOf(snapshotMonth)+2));
            if(Integer.valueOf(snapshotMonth)+3 <= 12) monthSet.add(String.valueOf(Integer.valueOf(snapshotMonth)+3));
          
            
            List<AggregateResult> sold = new List<AggregateResult>(
                [Select OA_Region__c reg, Sum(January__c), Sum(February__c), Sum(March__c),Sum(April__c),Sum(May__c),Sum(June__c),Sum(July__c),Sum(August__c),Sum(September__c),Sum(October__c),Sum(November__c),Sum(December__c) 
                 FROM OA_Data_Snapshots__c 
                 WHERE OA_Region__c IN: regionSet AND OA_Year__c=: selectedYear AND Snapshot_Month__c =: snapshotMonth AND OA_Probability__c = 100 
                 Group by Rollup(OA_Region__c)
                ]            
            );
            if(sold.size() == 0){
                OA_Utility.addMessage('Snapshot not captured for selected month and year.', 'Info');
                return;
            }
            for(AggregateResult ar : sold){
                key = String.valueOf(ar.get('reg'));
                if(!soldMap.containsKey(key)) soldMap.put(key, new Map<String, Decimal>());
                for(String month : monthSet){
                    if(Integer.valueOf(month) > 12 ) continue;
                    String expr = 'expr'+String.valueOf(Integer.valueOf(month) -1);
                    soldMap.get(key).put(month, (Decimal)ar.get(expr));
                }                       
            }        
            
            List<AggregateResult> pipeline = new List<AggregateResult>(
                [Select OA_Region__c reg, Sum(January_Weighted__c), Sum(February_Weighted__c), Sum(March_Weighted__c),Sum(April_Weighted__c),Sum(May_Weighted__c),Sum(June_Weighted__c),Sum(July_Weighted__c),Sum(August_Weighted__c),Sum(September_Weighted__c),Sum(October_Weighted__c),Sum(November_Weighted__c),Sum(December_Weighted__c) 
                 FROM OA_Data_Snapshots__c 
                 WHERE OA_Region__c IN: regionSet AND OA_Year__c=: selectedYear AND Snapshot_Month__c =: snapshotMonth AND OA_Probability__c < 100 
                 Group by Rollup(OA_Region__c)
                ]  
            );
            
            for(AggregateResult ar : pipeline){
                key = String.valueOf(ar.get('reg'));
                if(!pipelineMap.containsKey(key)) pipelineMap.put(key, new Map<String, Decimal>());
                for(String month : monthSet){
                    if(Integer.valueOf(month) > 12 ) continue;
                    String expr = 'expr'+String.valueOf(Integer.valueOf(month) -1);
                    pipelineMap.get(key).put(month, (Decimal)ar.get(expr));
                }                       
            }
            for(String month : monthSet){                
                ReportData totalRow = new ReportData();
                totalRow.Region = 'Global';
                totalRow.Month  = monthMap.get(month);                
                for(String region  : regionSet){                    
                    if(region == 'Global') continue;                    
                    if(Integer.valueOf(month) > 12 ) continue;
                    ReportData data = new ReportData();
                    data.region = region;
                    data.month = monthMap.get(month);
                    if(budgetMap.containsKey(region) && budgetMap.get(region).containsKey(monthMap.get(month))){
                        data.budget = (budgetMap.get(region).get(monthMap.get(month))/1000).setScale(1);
                        totalRow.budget += data.budget;
                    }else data.budget = 0;
                    /*if(forecastMap.containsKey(region) && forecastMap.get(region).containsKey(month)){
                        data.forecast = (forecastMap.get(region).get(month)/1000).setScale(1);
                    }else data.forecast = 0;*/
                    if(soldMap.containsKey(region) && soldMap.get(region).containsKey(month)){
                        data.sold = (soldMap.get(region).get(month)/1000).setScale(1);
                        totalRow.sold += data.sold;
                    }else data.sold = 0;
                    if(pipelineMap.containsKey(region) && pipelineMap.get(region).containsKey(month)){
                        data.pipeline = pipelineMap.get(region).get(month);
                        totalRow.pipeline += data.pipeline;
                    }else data.pipeline = 0;
                      
                    if(data.sold > data.budget){
                        data.surplus = data.sold - data.budget;
                        data.yettobeIdentified = 0;   
                        data.totalSold = data.sold;
                        data.sold = data.budget;
                    }else{
                         data.surplus = data.sold - data.budget;
                        data.totalSold = data.sold;
                        data.yettobeIdentified = data.budget - data.sold - data.pipeline; 
                        if(data.yettobeIdentified < 0){
                            data.yettobeIdentified = 0;
                        }
                    }
                    data.forecast = data.totalSold + data.pipeline;
                      data.Variance =data.forecast-data.budget;
                    dataList.add(data);
                }
                if(totalRow.sold > totalRow.budget){
                    totalRow.surplus = totalRow.sold - totalRow.budget;
                    totalRow.yettobeIdentified = 0;   
                    totalRow.totalSold = totalRow.sold;
                    totalRow.sold = totalRow.budget;
                }else{
                    totalRow.surplus = totalRow.sold - totalRow.budget;
                    totalRow.totalSold = totalRow.sold;
                    totalRow.yettobeIdentified = totalRow.budget - totalRow.sold - totalRow.pipeline; 
                    if(totalRow.yettobeIdentified < 0){
                        totalRow.yettobeIdentified = 0;
                    }
                }
                totalRow.forecast = totalRow.totalSold + totalRow.pipeline;
                totalRow.Variance =totalRow.forecast-totalRow.budget;
                if(selectedRegion == 'Global')dataList.add(totalRow);
                
            }
        }Catch(Exception e){
            OA_Utility.addMessage('Something went wrong, contact your system admin.', 'ERROR');
            System.debug('Error:'+e.getMessage() +'\n'+e.getStackTraceString());
        }
    }  
    
    public class ReportData{
        public String region{get;set;}
        public String month{get;set;}
        public Decimal budget{get;set;}
        public Decimal sold{get;set;}
        public Decimal totalSold{get;set;}
        public Decimal surplus{get;set;}
        public Decimal pipeline{get;set;}
        public Decimal forecast{get;set;}
        public Decimal yettobeIdentified{get;set;}
         public Decimal Variance{get;set;}
        public ReportData(){
            budget = 0.0;
            sold = 0.0;
            totalSold = 0.0;
            surplus = 0.0;
            pipeline = 0.0;
            forecast = 0.0;
            yettobeIdentified = 0.0;
        }
    }
}