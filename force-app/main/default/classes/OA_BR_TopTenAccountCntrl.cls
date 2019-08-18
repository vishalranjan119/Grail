public class OA_BR_TopTenAccountCntrl {
    public string selectedRegion{get;set;}
    public string selectedMonth{get;set;}   
    public string selectedYear{get;set;}    
    public List<SelectOption> regions{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    
    public List<ReportData> reportDataList{get;set;}
    
    public OA_BR_TopTenAccountCntrl(){
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
        List<AggregateResult> topTenAccounts = new List<AggregateResult>();
        List<AggregateResult> others = new List<AggregateResult>();
        try{
            if(Integer.valueOf(selectedYear) == System.today().year() &&
               (Integer.valueOf(selectedMonth) > System.today().month() ))
            {
                OA_Utility.addMessage('Snapshot month must not be greater than the current month for year: '+selectedYear, 'Info');
                return;
            }
            List<AggregateResult> aggregateResults = new List<AggregateResult>(
                [Select Account_Name__c, OA_Region__c, SUM(Gross__c) 
                 FROM OA_Data_Snapshots__c 
                 WHERE OA_Year__c=: selectedYear AND Snapshot_Month__c =:selectedMonth AND OA_Probability__c = 100 
                 Group By Account_Name__c,OA_Region__c
                  HAVING  SUM(Gross__c)>=50000
                 ORDER BY SUM(Gross__c) DESC
                ]
            );
            
            if(aggregateResults.isEmpty()){
                OA_Utility.addMessage('Snapshot not captured for selected month and year.', 'Info');
                return;
            }
            Decimal totalSold = 0.0;
            for(AggregateResult ar : aggregateResults){
                if(selectedRegion != 'Global' && selectedRegion != (String)ar.get('OA_Region__c') ) continue;
                topTenAccounts.add(ar);                               
                totalSold += (Double)ar.get('expr0');            
            }    
            
            for(AggregateResult ar : topTenAccounts){
                ReportData data = new ReportData(
                    (String)ar.get('Account_Name__c'),
                    (Double)ar.get('expr0'),
                    ((Double)ar.get('expr0')/totalSold)*100
                );  
                
                reportDataList.add(data);
            }
            
            /*Decimal otherAccountSold = 0.0;
            for(AggregateResult ar : others){
                otherAccountSold += (Double)ar.get('expr0');
            } 
            reportDataList.add(new ReportData('',null,null));           
            reportDataList.add(new ReportData('Others',otherAccountSold,(otherAccountSold/totalSold)* 100));*/
            reportDataList.add(new ReportData('',null,null));   
            reportDataList.add(new ReportData('Total',totalSold,100));   
            
            
        }Catch(Exception e){
            System.debug('Error:'+e.getMessage());
            System.debug('StackTrac:'+e.getStackTraceString());
            OA_Utility.addMessage('Data not found for selected criteria. Change the criteria and try again.', 'Info');
        }
        
    }
    
    public class ReportData{
        public String AccountName{get;set;}
        public Decimal Sold{get;set;}
        public Decimal SoldPercentage{get;set;}
        
        public ReportData(String AccountName, Decimal Sold, Decimal SoldPercentage){
            this.AccountName = AccountName;
            this.Sold = Sold != null ? (Sold/1000).setscale(2) : null;
            this.SoldPercentage = SoldPercentage!=null ? SoldPercentage.setScale(2) : null;
        }
    }
    
}