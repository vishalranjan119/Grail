public class OA_BR_BookedSalesVSHAvrgsCntrl {
    public String selectedYear{get;set;}
    public String selectedMonth{get;set;}    
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<ReportData> dataList{get;set;}
    public Map<String, String> monthMap{get;set;}
    
    public OA_BR_BookedSalesVSHAvrgsCntrl(){
        init();
    }
    
    
    
    public void init(){
        months = OA_ReportUtility.getMonthList();
        years = OA_ReportUtility.getYearList();       
        selectedYear   =  String.valueOf(System.today().year());
        selectedMonth  =  String.valueOf(System.today().month()-1);
        prepareReportData();
    }
    
    public void prepareReportData(){  
        
        dataList = new List<ReportData>();
        try{        
            if(Integer.valueOf(selectedYear) == System.today().year() &&
               (Integer.valueOf(selectedMonth) > System.today().month() )
              ){
                  OA_Utility.addMessage('Snapshot month must not be greater than the current month for year: '+selectedYear, 'Info');
                  return;
              }
            Integer averageStartYear = Integer.valueOf(selectedYear) - Integer.valueOf(Label.OA_ReportAverageYears) < = 2016 
                					   ? 2016 : Integer.valueOf(selectedYear) - Integer.valueOf(Label.OA_ReportAverageYears);
            If(averageStartYear == Integer.valueOf(selectedYear)){
                OA_Utility.addMessage('Historical Data not found for selected year', 'Info');
                return;
            }
            
            Map<String, Decimal> pYearsTotalSold = new Map<String, Decimal>();
            Integer count = 0;
            for(integer i=averageStartYear; i<Integer.valueOf(selectedYear); i++){
                Map<String, Decimal> pYearSold = getYearEndSoldByRegion(String.valueOf(i), selectedMonth);  
                if(pYearSold == null) return;
                for(String region : pYearSold.keyset()){
                    if(!pYearsTotalSold.containsKey(region))pYearsTotalSold.put(region,0);
                    pYearsTotalSold.put(region, pYearsTotalSold.get(region)+pYearSold.get(region));
                }
                count += 1;
            }
            Map<String, Decimal> selectedYearSold = getYearEndSoldByRegion(selectedYear, selectedMonth);
            if(selectedYearSold == null){
                OA_Utility.addMessage('Snapshot not captured for selected year and month', 'Info');
                return;
            } 
            for(String region : pYearsTotalSold.keyset()){
                ReportData data = new ReportData();
                data.Region = region;
                data.pAvrg = (pYearsTotalSold.get(region)/(count*1000)).setScale(2);
                data.bookedSales = selectedYearSold != null && selectedYearSold.containsKey(region) && selectedYearSold.get(region) != null ? (selectedYearSold.get(region)/1000).setScale(2): 0;
                if(data.pAvrg == null || data.bookedSales == 0) continue;
                data.difference = (data.bookedSales - data.pAvrg);
                dataList.add(data);           
            }   
        }Catch(Exception e){
            OA_Utility.addMessage('Something went wrong, contact your system admin.', 'Error');
        }     
    }
    
    public Map<String, Decimal> getYearEndSoldByRegion(String year, String month){
        List<AggregateResult> results = new List<AggregateResult>(
            [Select OA_Region__c,Sum(Gross__c) FROM OA_Data_Snapshots__c 
            WHERE OA_Year__c =:year AND Snapshot_Month__c =:month AND OA_Probability__c = 100  
            Group By Rollup(OA_Region__c)]
        );
        if(results.isEmpty()) return null;
        Map<String, Decimal>  monthlySoldMap = new Map<String, Decimal>();
        for(AggregateResult result : results){
            String key = (String)result.get('OA_Region__c');            
            if(key == null || key == '') key = 'Global';
            monthlySoldMap.put(key, (Decimal)result.get('expr0'));
        }
        return monthlySoldMap;
    }
    
    
    
    public class ReportData{
        public String Region{get;set;}
        public Decimal pAvrg{get;set;}
        public Decimal bookedSales{get;set;}
        public Decimal difference{get;set;}
    }

}