public class OA_BR_YTDCummulativeRevCntrl {
    
    public String selectedYear{get;set;}
    public String selectedMonth{get;set;}
    public String selectedRegion{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<SelectOption> regions{get;set;}
    public Map<String, String> monthMap{get;set;} 
    public List<ReportData> dataList{get;set;}    
    public List<String> monthList{get;set;}
    public String reportId{get;set;}
    
    public OA_BR_YTDCummulativeRevCntrl(){
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
        try{
            if(Integer.valueOf(selectedYear) == System.today().year() &&
               (Integer.valueOf(selectedMonth) > System.today().month() )
              ){
                  OA_Utility.addMessage('Snapshot month must not be greater than the current month for year: '+selectedYear, 'Info');
                  return;
              }
            for(integer i=2016; i<Integer.valueOf(selectedYear); i++){
                dataList.add(new ReportData(String.valueOf(i),String.valueOf(i), '12', selectedRegion, false));
            }        
            if(dataList.isEmpty()) return;
            Integer count = dataList.size();
            ReportData cYear = new ReportData(selectedYear,selectedYear, selectedMonth, selectedRegion, true);
            if(cYear == null){
                OA_Utility.addMessage('Data not found for selected year.', 'Info');
                return;
            }
            
            ReportData averageRow = new ReportData('Average');
            averageRow.PYear ='Average';
            ReportData targetRow = new ReportData('Target');
            targetRow.PYear='Target';
            ReportData varianceRow = new ReportData('Variance');
            varianceRow.PYear='Variance';
            Decimal target = 0;
            Decimal key = 0;
            for(String month : monthList){
                key = monthList.indexOf(month) + 1;
                Decimal pYearTotalSold = 0;
                Decimal pYearActualTotalSold = 0;
                Decimal pYearTotalPrcntg = 0;
                for(integer i=0; i<count; i++){                    
                    pYearTotalSold += dataList[i].monthlyTrendingSoldMap.get(month);
                    pYearActualTotalSold += dataList[i].monthlyActualSoldMap.get(month);
                    pYearTotalPrcntg += dataList[i].monthlySoldPrcntgMap.get(month);  
                }
                averageRow.monthlyTrendingSoldMap.put(month,(pYearTotalSold/count).setScale(1));
                averageRow.monthlyActualSoldMap.put(month,(pYearActualTotalSold/count).setScale(1));
                averageRow.monthlySoldPrcntgMap.put(month,(pYearTotalPrcntg/count).setScale(1));
                
                targetRow.monthlySoldPrcntgMap.put(month,0);
                varianceRow.monthlySoldPrcntgMap.put(month,0);
               	target = ((pYearTotalPrcntg/count)*cYear.SubTotal/100).setScale(1);
                if(key !=1){
                     Decimal cMonthAvrgPrcntg =  averageRow.monthlySoldPrcntgMap.get(monthMap.get(String.valueOf(key))) - averageRow.monthlySoldPrcntgMap.get(monthMap.get(String.valueOf(key-1)));
                     target = (cMonthAvrgPrcntg*cYear.SubTotal/100).setScale(1);
                }
                targetRow.monthlyActualSoldMap.put(month, target);
                if(cYear.monthlyActualSoldMap.get(month) == 0 ) continue;
                varianceRow.monthlyActualSoldMap.put(month, cYear.monthlyActualSoldMap.get(month)- targetRow.monthlyActualSoldMap.get(month));
               
            }
           
            dataList.add(averageRow);
            dataList.add(cYear);
			dataList.add(targetRow);
            dataList.add(varianceRow);
            
            for(ReportData data : dataList){
                for(String month : monthList){
                    data.monthlyActualSoldMap.put(month, (data.monthlyActualSoldMap.get(month)/1000).setScale(1));
                }
                
            }
            
        }Catch(Exception e){
            dataList.clear();
            OA_Utility.addMessage('Correct data not found in the system for the selected year.', 'Info');
            System.debug('Info:'+e.getMessage()+'\n'+ e.getStackTraceString());
        }
        
    }
    
   
    
    
    public class ReportData{
        public Decimal YearEndSold_budget{get;set;}
        public String Year{get;set;}
        public String PYear{get;set;}
        public Map<String,Decimal> monthlyTrendingSoldMap{get;set;}
        public Map<String,Decimal> monthlyActualSoldMap{get;set;}
        public Map<String,Decimal> monthlySoldPrcntgMap{get;set;}
        public Decimal SubTotal{get;set;}
        
        public ReportData(String year, String Pyear,String month, String region, boolean currentYear){
            this.Year = currentYear ? year+' (Sold)' : year;
            this.PYear = currentYear ? Year+' (As % Of Budget)' : year;   
            monthlyTrendingSoldMap = new Map<String,Decimal>();
            monthlySoldPrcntgMap = new Map<String,Decimal>();
            monthlyActualSoldMap = new Map<String,Decimal>();
            SubTotal = 0;
            for(String key : OA_ReportUtility.getMonthMap().keyset()){
                monthlyTrendingSoldMap.put(OA_ReportUtility.getMonthMap().get(key), 0);
                monthlyActualSoldMap.put(OA_ReportUtility.getMonthMap().get(key), 0);
                monthlySoldPrcntgMap.put(OA_ReportUtility.getMonthMap().get(key), 0);
            }
            
            
            for(AggregateResult result : getSoldData(year, month, region)){
                for(integer i = 0; i<12;i++){
                    if(currentYear &&  i >= Integer.valueOf(month)) continue;
                 	String exp = 'expr'+String.valueOf(i);
                    Decimal amnt = (Decimal)result.get(exp) != null ? (Decimal)result.get(exp) : 0;
                    monthlyActualSoldMap.put(OA_ReportUtility.getMonthMap().get(String.valueOf(i+1)),amnt);                     
                    if(i==0){
                        monthlyTrendingSoldMap.put(OA_ReportUtility.getMonthMap().get(String.valueOf(i+1)),amnt);
                        continue;
                    }
                    Decimal preAmnt = monthlyTrendingSoldMap.get(OA_ReportUtility.getMonthMap().get(String.valueOf(i)));
                    monthlyTrendingSoldMap.put(OA_ReportUtility.getMonthMap().get(String.valueOf(i+1)),amnt+preAmnt);                  
                }
                SubTotal =  currentYear ? OA_ReportUtility.getYearEndBudget(year, region) : monthlyTrendingSoldMap.get('December');
                for(String key : monthlyTrendingSoldMap.keyset()){
                    Decimal prcntg = SubTotal != 0 ? ((monthlyTrendingSoldMap.get(key)*100)/SubTotal).setScale(1) : 0;
                    monthlySoldPrcntgMap.put(key,prcntg);
                }
            }
            
            
            
        }
        
        public ReportData(String year){
            this.Year = year;
            monthlyTrendingSoldMap = new Map<String,Decimal>();
            monthlySoldPrcntgMap = new Map<String,Decimal>(); 
            monthlyActualSoldMap = new Map<String,Decimal>(); 
            for(String key : OA_ReportUtility.getMonthMap().keyset()){
                monthlyTrendingSoldMap.put(OA_ReportUtility.getMonthMap().get(key), 0);
                monthlySoldPrcntgMap.put(OA_ReportUtility.getMonthMap().get(key), 0);
                monthlyActualSoldMap.put(OA_ReportUtility.getMonthMap().get(key), 0);
            }
        }
        
        public List<AggregateResult> getSoldData(String year, String month, String region){
            List<AggregateResult> results = new List<AggregateResult>();
            String baseQuery = 'Select Sum(January__c),Sum(February__c),Sum(March__c),Sum(April__c),Sum(May__c),Sum(June__c),Sum(July__c),Sum(August__c),Sum(September__c),Sum(October__c),Sum(November__c),Sum(December__c) FROM OA_Data_Snapshots__c';
            String whereClouse = ' WHERE OA_Year__c = '+'\''+year+'\' AND OA_Probability__c = 100 AND Snapshot_Month__c='+'\''+month+'\'' ;
            if(region != 'Global'){
                whereClouse += ' AND OA_Region__c='+'\''+region+'\'';
            }
            String finalQuery = baseQuery + whereClouse;  
            
            return Database.query(finalQuery);
        }
        
        
        
    }

}