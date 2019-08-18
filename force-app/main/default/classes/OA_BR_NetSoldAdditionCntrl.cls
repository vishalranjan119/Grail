public class OA_BR_NetSoldAdditionCntrl {
    
    
    public string selectedRegion{get;set;}
    public string selectedFromMonth{get;set;}
    public string selectedToMonth{get;set;}
    public string selectedFromYear{get;set;} 
    public string selectedToYear{get;set;} 
    public List<SelectOption> regions{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<ReportData> reportDataList{get;set;}
    
    public Decimal totalSoldTillFrom{get;set;}
    public Decimal totalSoldTillTo{get;set;}
    
    public OA_BR_NetSoldAdditionCntrl(){
        init();
    }
    
    public void init(){
        regions = OA_ReportUtility.getRegionList();
        years = OA_ReportUtility.getYearList();
        months = OA_ReportUtility.getMonthList();
        selectedRegion = 'Global';
        selectedToMonth  = String.valueOf(System.today().month()-1);
        selectedFromMonth = String.valueOf(System.today().month()-2);
        selectedFromYear   = String.valueOf(System.today().year());  
        selectedToYear   = String.valueOf(System.today().year()); 
        prepareReportData();
    }
    
    public void prepareReportData(){
        reportDataList = new List<ReportData>();
        totalSoldTillFrom = 0;
        totalSoldTillTo = 0;
        try{
           
            List<AggregateResult> sold_till_from = new List<AggregateResult>(
                (List<AggregateResult>)Database.query(getQuery(selectedFromMonth,selectedFromYear,selectedRegion))
            );
            List<AggregateResult> sold_till_to = new List<AggregateResult>(
                (List<AggregateResult>)Database.query(getQuery(selectedToMonth,selectedToYear,selectedRegion))
            );
            
            Map<String,Decimal> soldTillFromMap = getFormattedMap(sold_till_from);
            Map<String,Decimal> soldTillToMap = getFormattedMap(sold_till_to);
            
            Set<String> accNames = new Set<String>(soldTillFromMap.keyset());
            accNames.addAll(soldTillToMap.keyset());
            
            for(String accName : accNames){
                ReportData data = new ReportData();
                data.AccountName = accName;
                if(soldTillFromMap.containsKey(accName)){
                    data.SodlTillFromMonth = (soldTillFromMap.get(accName)/1000).setscale(2);
                    totalSoldTillFrom += soldTillFromMap.get(accName);
                } else data.SodlTillFromMonth = 0;
                if(soldTillToMap.containsKey(accName)){
                    data.SodlTillToMonth = (soldTillToMap.get(accName)/1000).setscale(2);
                    totalSoldTillTo +=soldTillToMap.get(accName);
                } else data.SodlTillToMonth = 0;
                data.NetAddition = data.SodlTillToMonth - data.SodlTillFromMonth;
                reportDataList.add(data);
            }
            reportDataList.add(new ReportData());
            ReportData totalRow = new ReportData();
            totalRow.Region = 'Global';
            totalRow.AccountName = 'Total';
            totalRow.SodlTillFromMonth = (totalSoldTillFrom/1000).setscale(2);
            totalRow.SodlTillToMonth = (totalSoldTillTo/1000).setscale(2);
            totalRow.NetAddition =  totalRow.SodlTillToMonth - totalRow.SodlTillFromMonth;
            reportDataList.add(totalRow);
        }Catch(Exception e){
            System.debug('Exception: '+e.getStackTraceString());
            OA_Utility.addMessage('Did not found correct data for selected criteria. Please change the criteria and try again.', 'Info');
        }
        
    }
    private Map<String, Decimal> getFormattedMap(List<AggregateResult> results){
        if(results == null || results.isEmpty()) return null;
        Map<String, Decimal> formattedMap = new Map<String, Decimal>();
        for(AggregateResult ar : results){
            // if(selectedRegion != 'Global' && selectedRegion != (String)ar.get('OA_Region__c')) continue;
            formattedMap.put(
                (String)ar.get('Account_Name__c'),
                (Double)ar.get('expr0')
            );            
        }
        return formattedMap;
    }
    
    private String getQuery( String month,String year, String region){
        String baseQuery = 'Select Account_Name__c, SUM(Gross__c) FROM OA_Data_Snapshots__c ';
        String whereClouse = 'WHERE OA_Year__c=\''+ year+'\' AND Snapshot_Month__c =\''+month+'\' AND OA_Probability__c = 100 ';
        if(region != 'Global'){
            whereClouse += ' AND OA_Region__c=\''+region+'\'';
        }
        String groupBy = ' Group By Account_Name__c';
        String orderBy = ' ORDER BY SUM(Gross__c) DESC';
        String query = baseQuery+ whereClouse+groupBy+orderBy;
        System.debug('finalQuery'+query);
        return query;
    }
    
    public class ReportData{
        public String Region{get;set;}
        public String AccountName{get;set;}
        public Decimal SodlTillFromMonth{get;set;}
        public Decimal SodlTillToMonth{get;set;}
        public Decimal NetAddition{get;set;}
    }
    
}