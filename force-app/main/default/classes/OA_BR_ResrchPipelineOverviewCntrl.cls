public class OA_BR_ResrchPipelineOverviewCntrl {
    public String selectedYear{get;set;}
    public String selectedMonth{get;set;}
    public String selectedRegion{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<SelectOption> regions{get;set;}
    public transient List<ReportData> dataList{get;set;}
    
    public OA_BR_ResrchPipelineOverviewCntrl(){
        years = OA_ReportUtility.getYearList();        
        init();
    }
    
    public String toTitleCase(String phrase){
        String titlePhrase = '';
        //a set of words that should always (or at least, almost always) be in lower case when in Title Case
        //eg The Day of the Jackal.  First and last word of a phrase should always be Capped though.
        Set<String> forceLower = new Set<String>{'of', 'the', 'for', 'and', 'a', 'to', 'at' ,'an', 'but', 'if', 'or', 'nor'};
            
            if(phrase != null && phrase.length() > 0){
                String[] splitPhrase = phrase.trim().split(' ');
                
                for(integer i = 0; i < splitPhrase.size(); i++){
                    if(!forceLower.contains(splitPhrase[i].toLowerCase()) || i == 0 || i == (splitPhrase.size()-1) ){
                        titlePhrase += (splitPhrase[i].substring(0,1).toUpperCase())+(splitPhrase[i].substring(1).toLowerCase())+' ';
                    }else{
                        titlePhrase += splitPhrase[i].toLowerCase()+' ';
                    }
                }
            }
        return titlePhrase.trim();
    }
    
    public void init(){
        months = OA_ReportUtility.getMonthList();
        years = OA_ReportUtility.getYearList();
        regions = OA_ReportUtility.getRegionList();
        selectedRegion = 'Global';
        selectedYear   = String.valueOf(System.today().year());
        selectedMonth  =  String.valueOf(System.today().month()-1);
        //monthMap = OA_ReportUtility.getMonthMap(); 
        
        prepareReportData();
    }
    
    public void prepareReportData(){      
        try{
            dataList = new List<ReportData>();
            Set<String> regionSet = new Set<String>{selectedRegion};
                if(selectedRegion == 'Global'){
                    for(SelectOption region : regions){
                        regionSet.add(region.getValue());
                    }
                }
            
            Map<String, Map<String, Decimal>> soldMap = new Map<String, Map<String, Decimal>>();
            Map<String, Map<String, Decimal>> pipelineMap = new Map<String, Map<String, Decimal>>();
            Map<String, Map<String, Decimal>> w_pipelineMap = new Map<String, Map<String, Decimal>>();
            Map<String, Map<String, Decimal>> budgetMap = new Map<String, Map<String, Decimal>>();
            Set<String> allAccounts = new Set<String>();
            
            if(Integer.valueOf(selectedYear) == System.today().year() &&
               (Integer.valueOf(selectedMonth) > System.today().month() )
              ){
                  OA_Utility.addMessage('Snapshot month must not be greater than the current month for year: '+selectedYear, 'Info');
                  return;
              }
            
            List<AggregateResult> soldResults = new List<AggregateResult>(
                [Select OA_Region__c region, Account_Name__c acc, SUM(Gross__c) sold FROM OA_Data_Snapshots__c 
                 WHERE OA_Year__c =:selectedYear AND OA_Probability__c = 100 AND Snapshot_Month__c =:selectedMonth AND OA_Region__c IN : regionSet
                 Group By Rollup(Account_Name__c,OA_Region__c) ORDER BY SUM(Gross__c) DESC]
            );
            
            for(AggregateResult ar : soldResults){
                if(!soldMap.containsKey((String)ar.get('region'))) soldMap.put((String)ar.get('region'), new Map<String,Decimal>());
                soldMap.get((String)ar.get('region')).put(
                    null != ar.get('acc') ? String.valueOf(ar.get('acc')) : null, 
                    (Decimal)ar.get('sold')
                );
                if(null != ar.get('acc'))allAccounts.add(String.valueOf(ar.get('acc')));
            }
            System.debug('pipelineMap:'+soldMap);
            List<AggregateResult> pipelineResults = new List<AggregateResult>(
                [Select OA_Region__c region, Account_Name__c acc, SUM(Gross__c) pipeline FROM OA_Data_Snapshots__c 
                 WHERE OA_Year__c =:selectedYear AND OA_Probability__c < 100 AND Snapshot_Month__c =:selectedMonth AND OA_Region__c IN : regionSet
                 Group By Rollup(OA_Region__c,Account_Name__c)]
            );
            
            for(AggregateResult ar : pipelineResults){
                if(!pipelineMap.containsKey((String)ar.get('region'))) pipelineMap.put((String)ar.get('region'), new Map<String,Decimal>());
                pipelineMap.get((String)ar.get('region')).put(
                    null != ar.get('acc') ? String.valueOf(ar.get('acc')) : null, 
                    (Decimal)ar.get('pipeline')
                );                
                if(null != ar.get('acc'))allAccounts.add(String.valueOf(ar.get('acc')));
            }
            
            
            List<AggregateResult> w_pipelineResults = new List<AggregateResult>(
                [Select OA_Region__c region, Account_Name__c acc, SUM(Risk_Adjusted__c) pipeline FROM OA_Data_Snapshots__c 
                 WHERE OA_Year__c =:selectedYear AND OA_Probability__c < 100 AND Snapshot_Month__c =:selectedMonth AND OA_Region__c IN : regionSet 
                 Group By Rollup(OA_Region__c,Account_Name__c)]
            );
            
            for(AggregateResult ar : w_pipelineResults){
                if(!w_pipelineMap.containsKey((String)ar.get('region'))) w_pipelineMap.put((String)ar.get('region'), new Map<String,Decimal>());
                w_pipelineMap.get((String)ar.get('region')).put(
                    null  != ar.get('acc') ? String.valueOf(ar.get('acc')) : null, 
                    (Decimal)ar.get('pipeline')
                );
                if(null != ar.get('acc'))allAccounts.add(String.valueOf(ar.get('acc')));
            }
            System.debug('regionSet:'+regionSet);
            List<AggregateResult> budgetResults = new List<AggregateResult>(
                [Select OA_Region__c reg, OA_Account__c acc, SUM(OA_Total_Budget__c) budget  FROM OA_Budget__c 
                 WHERE OA_Year__c =:selectedYear AND OA_Region__c IN : regionSet
                 Group By OA_Account__c, OA_Region__c
                ]                 
            );
            
            for(AggregateResult budget : budgetResults){
                if(!budgetMap.containsKey((String)budget.get('reg'))) budgetMap.put((String)budget.get('reg'), new Map<String,Decimal>());
                budgetMap.get((String)budget.get('reg')).put(String.valueOf(budget.get('acc')), (Decimal)budget.get('budget'));
                allAccounts.add(String.valueOf(budget.get('acc')));
            }
            
            
            ReportData totalRow = new ReportData();totalRow.Region = 'Total';
            for(String region : soldMap.keyset()){
                if(region == null) continue;
                for(String acc : allAccounts){
                    if(acc == null) continue;
                    ReportData data =  new ReportData();
                    data.Region = region;
                    data.AccountName = acc;
                    if(soldMap.get(region).containsKey(acc)){
                        data.Sold = (soldMap.get(region).get(acc)/1000).setScale(1);
                        totalRow.Sold +=  data.Sold;
                    }
                    else data.Sold = 0; 
                    
                    if(budgetMap.containsKey(region) && budgetMap.get(region).containsKey(acc)){
                        data.Budget = (budgetMap.get(region).get(acc)/1000).setScale(1);
                        totalRow.Budget +=  data.Budget;
                    }else data.Budget=0;
                    
                    if(pipelineMap.containsKey(region) && pipelineMap.get(region).containsKey(acc)){
                        data.Pipeline = (pipelineMap.get(region).get(acc)).setScale(1); 
                        totalRow.Pipeline +=  data.Pipeline;                 
                    }else{                        
                        data.Pipeline=0;
                    }
                    
                    if(w_pipelineMap.containsKey(region) && w_pipelineMap.get(region).containsKey(acc)){
                        data.WPipeline = (w_pipelineMap.get(region).get(acc)).setScale(1);
                        totalRow.WPipeline +=  data.WPipeline;                                         
                    }else data.WPipeline=0;
                    
                    data.SoldPlusPipeline  = data.Sold + data.Pipeline;
                    data.SoldPlusWPipeline = data.Sold + data.WPipeline;
                    
                    if(data.Budget != 0){
                        data.SoldPercentage = ((data.Sold/data.Budget)*100).setScale(1);
                        data.SoldPlusPipelinePrcntg = ((data.SoldPlusPipeline/data.Budget)*100).setScale(1);
                        data.SoldPlusWPipelinePrcntg = ((data.SoldPlusWPipeline/data.Budget)*100).setScale(1);
                    }else{
                        data.SoldPercentage = 0;
                        data.SoldPlusPipelinePrcntg = 0;
                        data.SoldPlusWPipelinePrcntg = 0;
                    }
                    if(data.Budget == 0 && data.Sold == 0 && data.Pipeline == 0) continue;
                    dataList.add(data);
                }                
            }
            totalRow.SoldPlusPipeline = totalRow.Sold + totalRow.Pipeline;
            totalRow.SoldPlusWPipeline = totalRow.Sold + totalRow.WPipeline;
            totalRow.SoldPercentage = totalRow.Budget != 0 ? ((totalRow.Sold/totalRow.Budget)*100).setScale(1) : 0.0;
            totalRow.SoldPlusPipelinePrcntg = totalRow.Budget != 0 ? ((totalRow.SoldPlusPipeline/totalRow.Budget)*100).setScale(1) : 0.0;
            totalRow.SoldPlusWPipelinePrcntg = totalRow.Budget != 0 ? ((totalRow.SoldPlusWPipeline/totalRow.Budget)*100).setScale(1) : 0.0;  
            
            if(dataList != null && dataList.size() > 0){              
                //dataList.add(0,new ReportData());
                dataList.add(0,totalRow);
            }
        }
        catch(Exception ex){
            OA_Utility.addMessage('Something went wrong, contact your system admin.', 'ERROR');
            System.debug('Error:'+ex.getMessage()+'\n'+ex.getStackTraceString());
        }
    }
    
    
    
    
    public class ReportData{
        public String Region{get;set;}
        public String AccountName{get;set;}
        public Decimal Budget{get;set;}
        public Decimal Sold{get;set;}
        public Decimal SoldPercentage{get;set;}
        public Decimal Pipeline{get;set;}
        public Decimal SoldPlusPipeline{get;set;}
        public Decimal SoldPlusPipelinePrcntg{get;set;}
        public Decimal WPipeline{get;set;}
        public Decimal SoldPlusWPipeline{get;set;}
        public Decimal SoldPlusWPipelinePrcntg{get;set;} 
        
        public ReportData(){
            this.Budget = 0.0;
            this.Sold = 0.0;
            this.SoldPercentage = 0.0;
            this.SoldPlusPipeline = 0.0;
            this.SoldPlusPipelinePrcntg = 0.0;
            this.WPipeline = 0.0;
            this.Pipeline = 0.0;
            this.SoldPlusWPipeline = 0.0;
            this.SoldPlusWPipelinePrcntg = 0.0;
        }
    }
}