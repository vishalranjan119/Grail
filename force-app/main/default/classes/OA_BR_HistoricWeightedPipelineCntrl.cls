public class OA_BR_HistoricWeightedPipelineCntrl {
    public String selectedYear{get;set;}
    public String selectedMonth{get;set;}
    public String selectedRegion{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<SelectOption> regions{get;set;}    
    public String pYear{get;set;}
    public String ppYear{get;set;}
    public Map<String, String> monthMap{get;set;}     
    public List<PipelineOverview> dataList{get;set;}   
    public List<String> monthList{get;set;}
    public String reportId{get;set;}
    
    
    public OA_BR_HistoricWeightedPipelineCntrl(){
        init();
    }
    
    public void init(){
        List<Report> reports = new List<Report>([Select Id FROM Report WHERE Name='Weighted Pipeline Report']);
        if(reports.size() > 0) reportId = reports[0].id;        
        months = OA_ReportUtility.getMonthList();
        years = OA_ReportUtility.getYearList();
        regions = OA_ReportUtility.getRegionList();
        selectedRegion = 'Global';
        selectedYear   =  String.valueOf(System.today().year());
        selectedMonth  =  String.valueOf(System.today().month()-1);
        
        monthList = new List<String>{
            'January','February','March','April','May','June','July','August','September','October','November','December'
        };
        prepareReportData();
        
    }
    
    
    public void prepareReportData(){
        dataList = new List<PipelineOverview>();
        pYear    = String.valueOf(Integer.valueOf(selectedYear) -1);
        ppYear   = String.valueOf(Integer.valueOf(selectedYear) -2);
        
        try{   
            if(Integer.valueOf(selectedYear) == System.today().year() &&
               (Integer.valueOf(selectedMonth) > System.today().month() )
              ){
                  OA_Utility.addMessage('Snapshot month must not be greater than the current month for year: '+selectedYear, 'Info');
                  return;
              }
            
            Integer averageStartYear = Integer.valueOf(selectedYear) - Integer.valueOf(Label.OA_ReportAverageYears) < = 2016 
                					   ? 2016 : Integer.valueOf(selectedYear) - Integer.valueOf(Label.OA_ReportAverageYears);
            for(integer i=averageStartYear; i<Integer.valueOf(selectedYear); i++){
                dataList.add(new PipelineOverview(getPipelineData(String.valueOf(i)),String.valueOf(i),String.valueOf(i),null,false, selectedRegion));
            }
            if(dataList.isEmpty()) return;
            Integer count = dataList.size();
            
            PipelineOverview cYear = new PipelineOverview(getPipelineData(selectedYear),selectedYear,selectedYear,selectedMonth,true,selectedRegion);
            System.debug(cYear);
            if(cYear == null) return;
            PipelineOverview averageRow = new PipelineOverview();
            averageRow.Year = 'Average';
            averageRow.PYear = 'Average';
            PipelineOverview targetRow = new PipelineOverview();
            targetRow.Year = 'Target';
            targetRow.PYear = 'Target';
            PipelineOverview varianceRow = new PipelineOverview();
            varianceRow.Year = 'Variance';
            varianceRow.PYear = 'Variance';
            
            for(String month : monthList){
                
                Decimal pYearsTotalSold = 0;
                Decimal pYearsTotalSoldPrcntg = 0;
                for(integer i=0; i<count; i++){
                    pYearsTotalSoldPrcntg += dataList[i].monthlyPipelinePrcntgMap.get(month);
                    pYearsTotalSold += dataList[i].monthlyPipelineMap.get(month);                    
                }
                averageRow.monthlyPipelineMap.put(month,(pYearsTotalSold/count).setScale(0));
                averageRow.monthlyPipelinePrcntgMap.put( month,(pYearsTotalSoldPrcntg/count).setScale(1));
                
                targetRow.monthlyPipelinePrcntgMap.put(month,0); 
                varianceRow.monthlyPipelinePrcntgMap.put(month,0);
                targetRow.monthlyPipelineMap.put(
                    month,
                    (((cYear.YearEndSold_budget/1000)*averageRow.monthlyPipelinePrcntgMap.get(month))/100).setScale(0)
                );
                
                
                varianceRow.monthlyPipelineMap.put(
                    month,
                    cYear.monthlyPipelineMap.get(month) != 0 ? cYear.monthlyPipelineMap.get(month) - targetRow.monthlyPipelineMap.get(month) : 0
                );
            }
            dataList.add(averageRow);
            dataList.add(cYear);            
            dataList.add(targetRow);
            dataList.add(varianceRow);
            
            for(PipelineOverview data : dataList){
                if(data.YearEndSold_budget == null) continue;
                data.YearEndSold_budget = (data.YearEndSold_budget/1000).setScale(0);
            }
        }Catch(Exception e){
            dataList.clear();
            System.debug('Error:'+e.getMessage() + e.getStackTraceString());
            OA_Utility.addMessage('Data not found in the system for selected year.', 'Info');
        }
        
    }
    
    public List<AggregateResult> getPipelineData(String year){
        List<AggregateResult> results = new List<AggregateResult>();
        String baseQuery = 'Select Snapshot_Month__c, SUM(Risk_Adjusted__c) FROM OA_Data_Snapshots__c';
        String whereClouse = ' WHERE OA_Year__c = '+'\''+year+'\' AND OA_Probability__c < 100';
        if(selectedRegion != 'Global'){
            whereClouse += ' AND OA_Region__c='+'\''+selectedRegion+'\'';
        }
       
        String groupBy = ' Group By Rollup(Snapshot_Month__c)';
        String finalQuery = baseQuery + whereClouse + groupBy;             
        return Database.query(finalQuery);
    }
    
    public class PipelineOverview{
        public String Year{get;set;}
        public String PYear{get;set;}
        public Decimal YearEndSold_budget{get;set;}
        public Map<String,Decimal> monthlyPipelineMap{get;set;}
        public Map<String,Decimal> monthlyPipelinePrcntgMap{get;set;}

        public Decimal SubTotal{get;set;}
        
        public PipelineOverview(List<AggregateResult> results, String Year, String PYear,String month, boolean currentYear, String region){                     
                        
            this.YearEndSold_budget = currentYear ?  OA_ReportUtility.getYearEndBudget(Year,region) : OA_ReportUtility.getYearEndRevenue(Year,region);
            this.Year = currentYear ? Year+' (Pipeline)' : Year;
            this.PYear = currentYear ? Year+' (As % Of Budget)' : Year;
            System.debug(' this.YearEndSold_budget:'+ this.YearEndSold_budget);
            if(results == null || results.isEmpty()) return;
            monthlyPipelineMap = new Map<String,Decimal>();
            monthlyPipelinePrcntgMap = new Map<String,Decimal>();
            for(String key : OA_ReportUtility.getMonthMap().keyset()){
                monthlyPipelineMap.put(OA_ReportUtility.getMonthMap().get(key), 0);
                monthlyPipelinePrcntgMap.put(OA_ReportUtility.getMonthMap().get(key), 0);
            }
            
            for(AggregateResult result : results){
                String snapshotMonth = (String)result.get('Snapshot_Month__c');
                Decimal amount = (Decimal)result.get('expr0');
                if(currentYear && snapshotMonth != null && Integer.valueOf(snapshotMonth) > Integer.valueOf(month))continue;
              	 
                monthlyPipelineMap.put(
                    OA_ReportUtility.getMonthMap().get(snapshotMonth), 
                    amount != null ? amount.setScale(0) : 0.0
                );
                
                monthlyPipelinePrcntgMap.put(
                    OA_ReportUtility.getMonthMap().get(snapshotMonth), 
                    YearEndSold_budget == 0 ? null : (((amount*1000)/YearEndSold_budget)*100).setScale(1)
                );
            }             
        }
        public PipelineOverview(){
            monthlyPipelineMap = new Map<String,Decimal>();
            monthlyPipelinePrcntgMap = new Map<String,Decimal>();
        }
    }

}