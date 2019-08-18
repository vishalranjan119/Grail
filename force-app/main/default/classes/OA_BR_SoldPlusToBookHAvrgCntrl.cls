public class OA_BR_SoldPlusToBookHAvrgCntrl {
    
    public String selectedYear{get;set;}
    public String selectedMonth{get;set;}
    public String selectedRegion{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<SelectOption> regions{get;set;}
    
    public String pYear{get;set;}
    public String ppYear{get;set;}
    public Map<String, String> monthMap{get;set;} 
    
    public List<ReportData> dataList{get;set;}
    
    public List<String> monthList{get;set;}
    public String reportId{get;set;}
    
    public OA_BR_SoldPlusToBookHAvrgCntrl(){
        init();
    }
    
    public void init(){
        List<Report> reports = new List<Report>([Select Id FROM Report WHERE Name='Historic Sales Report']);
        if(reports.size() > 0) reportId = reports[0].id;
        months = OA_ReportUtility.getMonthList();
        years = OA_ReportUtility.getYearList();
        regions = OA_ReportUtility.getRegionList();
        selectedRegion = 'Global';
        selectedYear   =  String.valueOf(System.today().year());
        selectedMonth  =  String.valueOf(System.today().month()-1);
        monthMap = OA_ReportUtility.getMonthMap();
        monthList = new List<String>{
            'January','February','March','April','May','June','July','August','September','October','November','December'
                };
                    prepareReportData();
        
    }
    
    
    public void prepareReportData(){
        dataList = new List<ReportData>();
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
                dataList.add(new ReportData(getSoldData(String.valueOf(i)),String.valueOf(i),String.valueOf(i),'12',false, selectedRegion));
            }
            if(dataList.isEmpty()) return;
            Integer count = dataList.size();
            ReportData currentYear = new ReportData(getSoldData(selectedYear),selectedYear,selectedYear,selectedMonth,true,selectedRegion);
            
            System.debug('currentYear:'+currentYear.monthlySoldMap);
            ReportData averageRow = new ReportData('Average');
            averageRow.PYear='Average';
            ReportData avgSalesAddnAnl = new ReportData('Avg. Sales Add (Annual)');
            ReportData avgSalesAddnMnthly = new ReportData('Avg. Sales Add (Monthly)');
            ReportData altForecast = new ReportData('Alt Forecast');
            
            
            for(String month : monthList){
                Decimal pYearTotalSold = 0;
                Decimal pYearTotalSoldPrcntg = 0;
                Decimal totalSoldAddnAnnl = 0;
                Integer currentMonth = monthList.indexOf(month)+1;
                Integer lastMonth = currentMonth - 1;
                avgSalesAddnAnl.monthlySoldPrcntgMap.put(month,'0');
                avgSalesAddnMnthly.monthlySoldPrcntgMap.put(month,'0');
                altForecast.monthlySoldPrcntgMap.put(month,'0');
                // Decimal.valueOf(value.replaceAll('[^.\\d]',''));
                for(integer i=0; i<count; i++){                    
                    pYearTotalSold += dataList[i].monthlySoldMap.get(month) != null ?Decimal.valueOf((dataList[i].monthlySoldMap.get(month)).replaceAll('[^.\\d]','')):0;
                    pYearTotalSoldPrcntg += dataList[i].monthlySoldPrcntgMap.get(month) != null ? Decimal.valueOf(dataList[i].monthlySoldPrcntgMap.get(month)) :0;                  
                    totalSoldAddnAnnl = totalSoldAddnAnnl + ((dataList[i].YearEndSold_budget/1000) - Decimal.valueOf((dataList[i].monthlySoldMap.get(month)).replaceAll('[^.\\d]','')));                    
                }
                decimal pTotalSold =(pYearTotalSold/count).setScale(0);
                decimal ptotalSoldAddnAnnl =(totalSoldAddnAnnl/count).setScale(0);
                List<String> args = new String[]{'0','number','###,###,##0.00'};
                String s1 = String.format(pTotalSold.format(), args);
                String s2 = String.format(ptotalSoldAddnAnnl.format(), args);
                
                averageRow.monthlySoldMap.put(month,s1);
                avgSalesAddnAnl.monthlySoldMap.put(month,s2);
                avgSalesAddnMnthly.monthlySoldMap.put(month, 'n/a');
                averageRow.monthlySoldPrcntgMap.put( month,String.valueOf((pYearTotalSoldPrcntg/count).setScale(1)));
                
                if(currentMonth < = Integer.valueOf(selectedMonth)){
                    avgSalesAddnMnthly.monthlySoldMap.put(month, 'n/a');
                    altForecast.monthlySoldMap.put(month,currentYear.monthlySoldMap.get(month));
                    continue;                    
                }
                Decimal monthlyAddnAvrg = Decimal.valueOf(averageRow.monthlySoldMap.get(month).replaceAll('[^.\\d]','')) - Decimal.valueOf(averageRow.monthlySoldMap.get(monthMap.get(String.valueOf(lastMonth))).replaceAll('[^.\\d]',''));
                Decimal altForecastAmount = Decimal.valueOf(altForecast.monthlySoldMap.get(monthMap.get(String.valueOf(lastMonth))).replaceAll('[^.\\d]','')) + monthlyAddnAvrg;
                String s3 = String.format(monthlyAddnAvrg.format(), args);
                String s4 = String.format(altForecastAmount.format(), args);
                avgSalesAddnMnthly.monthlySoldMap.put(month, s3);    						
                altForecast.monthlySoldMap.put(month,s4);
                
            }
            dataList.add(averageRow);
            dataList.add(currentYear);
            dataList.add(avgSalesAddnAnl);
            dataList.add(avgSalesAddnMnthly);
            dataList.add(altForecast);   
            
            for(ReportData data : dataList){
                if(data.YearEndSold_budget == null) continue;
                data.YearEndSold_budget = (data.YearEndSold_budget/1000).setScale(0);
            }
        }Catch(Exception e){
            dataList.clear();
            System.debug('Error:'+e.getMessage() + e.getStackTraceString());
            OA_Utility.addMessage('Error: Correct data not found in the system for selected criteria.', 'Info');
        }
        
    }
    
    public List<AggregateResult> getSoldData(String year){
        List<AggregateResult> results = new List<AggregateResult>();
        String baseQuery = 'Select Snapshot_Month__c, SUM(Gross__c) FROM OA_Data_Snapshots__c';
        String whereClouse = ' WHERE OA_Year__c = '+'\''+year+'\' AND OA_Probability__c = 100';
        if(selectedRegion != 'Global'){
            whereClouse += ' AND OA_Region__c='+'\''+selectedRegion+'\'';
        }
        
        String groupBy = ' Group By Rollup(Snapshot_Month__c)';
        String finalQuery = baseQuery + whereClouse + groupBy;             
        return Database.query(finalQuery);
    }
    
    public class ReportData{
        public String Year{get;set;}
        public String PYear{get;set;}
        public Decimal YearEndSold_budget{get;set;}       
        public Map<String,String> monthlySoldMap{get;set;}
        public Map<String,String> monthlySoldPrcntgMap{get;set;}
        public Decimal SubTotal{get;set;}
        
        public ReportData(List<AggregateResult> results, String Year,String PYear, String month, boolean currentYear, String region){                     
            if(results == null || results.isEmpty()) return;
            this.Year = currentYear ? Year+' (Sold)' : Year;  
            this.PYear = currentYear ? Year+' (As % Of Budget)' : Year; 
            //this.YearEndSold_budget = OA_ReportUtility.getYearEndRevenue(Year,region, month); 
            this.YearEndSold_budget = currentYear ? OA_ReportUtility.getYearEndBudget(Year,region) : OA_ReportUtility.getYearEndRevenue(Year,region);
            
            
            System.debug(' this.YearEndSold_budget:'+ this.YearEndSold_budget);
            if(results == null || results.isEmpty()) return; 
            monthlySoldMap = new Map<String,String>();
            monthlySoldPrcntgMap = new Map<String,String>();
            for(String key : OA_ReportUtility.getMonthMap().keyset()){
                monthlySoldMap.put(OA_ReportUtility.getMonthMap().get(key), ' ');
                monthlySoldPrcntgMap.put(OA_ReportUtility.getMonthMap().get(key), ' ');
            }
            
            for(AggregateResult result : results){
                String snapshotMonth = (String)result.get('Snapshot_Month__c');
                Decimal amount = ((Decimal)result.get('expr0')).setScale(0);
                
                if(currentYear && snapshotMonth != null && Integer.valueOf(snapshotMonth) > Integer.valueOf(month)){
                    //monthlySoldMap.put(OA_ReportUtility.getMonthMap().get(snapshotMonth), String.valueOf(YearEndSold_budget));
                    continue;
                }
                decimal am=(amount/1000).setScale(0);
                
                List<String> args = new String[]{'0','number','###,###,##0.00'};
                    String s = String.format(am.format(), args);
                System.debug(s);
                monthlySoldMap.put(
                    OA_ReportUtility.getMonthMap().get(snapshotMonth), 
                    s
                );
                decimal yrsold =((amount/YearEndSold_budget)*100).setScale(1);
                
                 String s8 = String.format(yrsold.format(), args);
                monthlySoldPrcntgMap.put(
                    OA_ReportUtility.getMonthMap().get(snapshotMonth), 
                    YearEndSold_budget == 0 ? null : s8              );
            } 
            
        }
        public ReportData(String year){
            this.Year = year;
            monthlySoldMap = new Map<String,String>();
            monthlySoldPrcntgMap = new Map<String,String>();
        }   
    } 
}