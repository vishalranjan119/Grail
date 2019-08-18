public class OA_BR_WeightedGrossPipelineCntrl {
    
    public string eastCoatsProbability{get;set;}
    public string westCoatsProbability{get;set;}
    public string europeProbability{get;set;}
    public string apacProbability{get;set;}
    public String selectedYear{get;set;}
    public String selectedMonth{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<ReportData> dataList{get;set;}
    
    public OA_BR_WeightedGrossPipelineCntrl(){
        init();
    }
    
    public void init(){
        eastCoatsProbability = '70';
        westCoatsProbability = '70';
        europeProbability = '70';
        apacProbability = '70';
        years = OA_ReportUtility.getYearList();
        months = OA_ReportUtility.getMonthList();    
        selectedMonth  = String.valueOf(System.today().month()-1);
        selectedYear   = String.valueOf(System.today().year());
        prepareReportData();
    }
    
    public void prepareReportData(){
        if(!isDecimal(eastCoatsProbability) 
           || !isDecimal(westCoatsProbability)
           || !isDecimal(europeProbability)
           || !isDecimal(apacProbability)
          )return;
        dataList = new List<ReportData>();
        try{
            if(Integer.valueOf(selectedYear) == System.today().year() &&
               (Integer.valueOf(selectedMonth) > System.today().month() ))
            {
                OA_Utility.addMessage('Snapshot month must not be greater than the current month for year: '+selectedYear, 'Info');
                return;
            }
            
            List<OA_Data_Snapshots__c> snapshots = new List<OA_Data_Snapshots__c>(
                [Select OA_Region__c,OA_Probability__c, Opportunity_Rep__r.Name, Account_Name__c, Opportunity_Name__c, Gross__c, Risk_Adjusted__c 
                 FROM OA_Data_Snapshots__c
                 WHERE ((OA_Region__c= 'East Coast US' AND OA_Probability__c >=: Decimal.valueOf(eastCoatsProbability)) OR (OA_Region__c=:'West Coast US' AND OA_Probability__c >=:Decimal.valueOf(westCoatsProbability)) OR (OA_Region__c=:'Europe' AND OA_Probability__c >=:Decimal.valueOf(europeProbability)) OR (OA_Region__c=:'APAC & MEA' AND OA_Probability__c >=:Decimal.valueOf(apacProbability))) AND OA_Year__c=:selectedYear AND Snapshot_Month__c=:selectedMonth AND OA_Probability__c < 100
                 Order By OA_Region__c
                ]
            );
            
            if(snapshots.size() == 0){
                OA_Utility.addMessage('Snapshot not captured for selected month and year.', 'Info');
                return;
            }
            
            for(OA_Data_Snapshots__c data : snapshots){
                ReportData rData = new ReportData(
                    data.OA_Region__c,
                    data.Opportunity_Rep__r.Name,
                    data.Account_Name__c,
                    data.Opportunity_Name__c,
                    data.Risk_Adjusted__c,
                    data.Gross__c,
                    data.OA_Probability__c
                );
                dataList.add(rData);
            }
            
            List<AggregateResult> subTotal = new List<AggregateResult>(
                [Select SUM(Gross__c), SUM(Risk_Adjusted__c) 
                 FROM OA_Data_Snapshots__c
                 WHERE ((OA_Region__c= 'East Coast US' AND OA_Probability__c >=: Decimal.valueOf(eastCoatsProbability)) OR (OA_Region__c=:'West Coast US' AND OA_Probability__c >=:Decimal.valueOf(westCoatsProbability)) OR (OA_Region__c=:'Europe' AND OA_Probability__c >=:Decimal.valueOf(europeProbability)) OR (OA_Region__c=:'APAC & MEA' AND OA_Probability__c >=:Decimal.valueOf(apacProbability))) AND OA_Year__c=:selectedYear AND Snapshot_Month__c=:selectedMonth AND OA_Probability__c < 100
                ]
            );
            
            List<AggregateResult> others = new List<AggregateResult>(
                [Select SUM(Gross__c), SUM(Risk_Adjusted__c)
                 FROM OA_Data_Snapshots__c
                 WHERE ((OA_Region__c= 'East Coast US' AND OA_Probability__c <: Decimal.valueOf(eastCoatsProbability)) OR (OA_Region__c=:'West Coast US' AND OA_Probability__c <:Decimal.valueOf(westCoatsProbability)) OR (OA_Region__c=:'Europe' AND OA_Probability__c <:Decimal.valueOf(europeProbability)) OR (OA_Region__c=:'APAC & MEA' AND OA_Probability__c <:Decimal.valueOf(apacProbability))) AND OA_Year__c=:selectedYear AND Snapshot_Month__c=:selectedMonth
                ]
            );
            dataList.add(new ReportData('','','','', null, null, null));
            ReportData subtotalRow = new ReportData('Subtotal','','','', 
                                                    (Decimal)subTotal[0].get('expr1'), 
                                                    (Decimal)subTotal[0].get('expr0'), 
                                                    ((Decimal)subTotal[0].get('expr1')/(Decimal)subTotal[0].get('expr0'))*100
                                                   );
            dataList.add(subtotalRow);
            
            dataList.add(new ReportData('','','','', null, null, null));
            ReportData othersRow = new ReportData('Others','','','', 
                                                  (Decimal)others[0].get('expr1'), 
                                                  (Decimal)others[0].get('expr0'),
                                                  ((Decimal)others[0].get('expr1')/(Decimal)others[0].get('expr0'))*100                                    
                                                 );
            dataList.add(othersRow);                   
            dataList.add(new ReportData('','','','', null, null, null));
            dataList.add(new ReportData('Total','','','', 
                                        (Decimal)subTotal[0].get('expr1') + (Decimal)others[0].get('expr1'), 
                                        (Decimal)subTotal[0].get('expr0') + (Decimal)others[0].get('expr0'), 
                                        ((subtotalRow.WPipeline + othersRow.WPipeline)/(subtotalRow.GPipeline + othersRow.GPipeline))*100
                                       )); 
        }Catch(Exception ex){
            OA_Utility.addMessage(ex.getMessage(), 'Error');
        }
        
    }
    
    public boolean isDecimal(String probability){
        try{
            Decimal.valueOf(probability);
            return true;
        }Catch(Exception e){
            return false;
        }
    }
    
    
    public class ReportData{
        public String Region{get;set;}
        public String Rep{get;set;}
        public String AccountName{get;set;}
        public String OpportunityName{get;set;}
        public Decimal WPipeline{get;set;}
        public Decimal GPipeline{get;set;}
        public Decimal Probability{get;set;}
        
        public ReportData(String Region, String Rep, String accName, String oppName, Decimal WP, Decimal GP, Decimal P){
            this.Region = Region;
            this.Rep = Rep;
            this.AccountName = accName;
            this.OpportunityName = oppName;
            this.WPipeline = WP;
            this.GPipeline = GP;
            this.Probability = P != null ? P.setScale(2) : null;
        }
    }
    
}