public class OA_BR_BudgetvsForecastPageCntrl {
    
    public string selectedRegion{get;set;}
    public string selectedMonth{get;set;}
    public string selectedYear{get;set;}    
    public List<SelectOption> regions{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<ReportData> reportDataList{get;set;}
    
    public OA_BR_BudgetvsForecastPageCntrl(){
        init();
    }
    
    public void init(){
        regions = OA_ReportUtility.getRegionList();
        years = OA_ReportUtility.getYearList();
        months = OA_ReportUtility.getMonthList();
        selectedRegion = 'Global';
        selectedMonth  = String.valueOf(System.today().month()-1);
        selectedYear   = String.valueOf(System.today().year());  
        
        prepareReportData();
    }
    
    public void prepareReportData(){
        reportDataList = new List<ReportData>();
        try{
            if(Integer.valueOf(selectedYear) == System.today().year() &&
               (Integer.valueOf(selectedMonth) > System.today().month() ))
            {
                OA_Utility.addMessage('Snapshot month must not be greater than the current month for year: '+selectedYear, 'Info');
                return;
            }
            Decimal sold = 0.0;
            Decimal pipeline = 0.0;
            Decimal budget = 0.0;
            List<AggregateResult> sold_results = new List<AggregateResult>(
                [Select OA_Region__c, Sum(January__c), Sum(February__c), Sum(March__c),Sum(April__c),Sum(May__c),Sum(June__c),Sum(July__c),Sum(August__c),Sum(September__c),Sum(October__c),Sum(November__c),Sum(December__c) 
                 FROM OA_Data_Snapshots__c 
                 WHERE OA_Year__c=: selectedYear AND Snapshot_Month__c =: selectedMonth AND OA_Probability__c = 100 
                 Group by Rollup(OA_Region__c)
                ]
            );
            System.debug('sold_results:'+sold_results);
            if(sold_results.size() == 0){
                OA_Utility.addMessage('Snapshot not captured for selected month and year.', 'Info');
                return;
            }
            List<AggregateResult> pipeline_results = new List<AggregateResult>(
                [Select OA_Region__c, Sum(January_Weighted__c), Sum(February_Weighted__c), Sum(March_Weighted__c),Sum(April_Weighted__c),Sum(May_Weighted__c),Sum(June_Weighted__c),Sum(July_Weighted__c),Sum(August_Weighted__c),Sum(September_Weighted__c),Sum(October_Weighted__c),Sum(November_Weighted__c),Sum(December_Weighted__c) 
                 FROM OA_Data_Snapshots__c 
                 WHERE OA_Year__c=: selectedYear AND Snapshot_Month__c =: selectedMonth AND OA_Probability__c < 100 
                 Group by Rollup(OA_Region__c)
                ]
            );
            Map<String,Map<String, Decimal>> soldResultMap =  getFormattedMap(sold_results);               
            Map<String,Map<String, Decimal>> pipelineResultMap = getFormattedMap(pipeline_results);
            Map<String,Map<String, Decimal>> monthlyBudget = OA_ReportUtility.getRegionlQuotaByMonth(selectedYear);
            
            for(String region : soldResultMap.keyset()){
                if(region == 'Global') continue;
                if(selectedRegion != 'Global' && selectedRegion != region) continue;
                
                for(String  month : soldResultMap.get(region).keyset()){
                    ReportData reportData = new ReportData(
                        region,
                        month,
                        selectedYear,
                        soldResultMap.containsKey(region) && soldResultMap.get(region).containsKey(month) ? soldResultMap.get(region).get(month) : 0.0,
                        pipelineResultMap.containsKey(region) && pipelineResultMap.get(region).containsKey(month) ? pipelineResultMap.get(region).get(month) : 0.0,
                        monthlyBudget.containsKey(region) && monthlyBudget.get(region).containsKey(month) ? monthlyBudget.get(region).get(month) : 0.0
                    );   
                    reportDataList.add(reportData);
                }
            } 
        }Catch(Exception e){
            System.debug('Error:'+e.getMessage());
            System.debug('StackTrace:'+e.getStackTraceString());
            OA_Utility.addMessage('Data not found in the system for selected criteria', 'Info');
        }      
    }
    
    private Map<String,Map<String, Decimal>> getFormattedMap(List<AggregateResult> results){
        if(results == null || results.isEmpty()) return null;
        Map<String,Map<String, Decimal>> formattedMap = new Map<String,Map<String, Decimal>>();
        for(AggregateResult ar : results){
            Map<String, Decimal> innerMap = new Map<String, Decimal>();
            innerMap.put('January', (double)ar.get('expr0'));
            innerMap.put('February', (double)ar.get('expr1'));
            innerMap.put('March', (double)ar.get('expr2'));
            innerMap.put('April', (double)ar.get('expr3'));
            innerMap.put('May', (double)ar.get('expr4'));
            innerMap.put('June', (double)ar.get('expr5'));
            innerMap.put('July', (double)ar.get('expr6'));
            innerMap.put('August', (double)ar.get('expr7'));
            innerMap.put('September', (double)ar.get('expr8'));
            innerMap.put('October', (double)ar.get('expr9'));
            innerMap.put('November', (double)ar.get('expr10'));
            innerMap.put('December', (double)ar.get('expr11'));
            String key = (String)ar.get('OA_Region__c');
            if(key == null) key = 'Global';
            formattedMap.put(key, innerMap);
        }
        return formattedMap;
    }
    
    
    public class ReportData{
        public String Region{get;set;}
        public String Month{get;set;}
        public String Year{get;set;}
        public Decimal Sold {get;set;} 
        public Decimal TotalSold {get;set;} 
        public Decimal Forecast {get;set;} 
        public Decimal Weighted_Pipeline{get;set;}  
        public Decimal Budget {get;set;}   
        public Decimal Surplus {get;set;}   
        public Decimal PrevSold {get;set;} 
        public Decimal Yet_To_Be_Identified{get;set;}
        
        public ReportData(String Region, String Month, String Year, Decimal Sold, Decimal Weighted_Pipeline, Decimal Budget){
            this.Region = Region;
            this.Month = Month;
            this.Year = Year;
            this.Sold = (Sold/1000).setScale(2);
            this.Weighted_Pipeline = Weighted_Pipeline;
            this.Budget = (Budget/1000).setScale(2);
            if(this.Sold > this.Budget){
                Surplus = ((Sold - Budget)/1000).setScale(2);
                Yet_To_Be_Identified = 0.0;
                this.Sold = this.Budget;
            } 
            else{
                Surplus = 0.0;
                Yet_To_Be_Identified = this.Budget - this.Sold - Weighted_Pipeline;
                if(Yet_To_Be_Identified < 0) Yet_To_Be_Identified = 0;
            }
            this.TotalSold =  this.Sold + Surplus;
            this.Forecast =  this.Sold + Surplus + this.Weighted_Pipeline;
            
            
        }       
    }
}