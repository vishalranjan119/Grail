/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_MonthlyRevenueSalesReportController
Class Purpose: Board Report-Sales Goal Tracking View - Sold Vs Budgeted [Overall and Region Wise]
Versions: 1.1
******************************************************************************************************/
public class OA_BR_SalesGoalViewCntrl {
    public String selectedRegion{get;set;}
    public String selectedYear{get;set;}
    public String selectedMonth{get;set;}
    public List<SelectOption> regions{get;set;}
    public List<SelectOption> months{get;set;}
    public List<SelectOption> years{get;set;}
    public List<AggregateResult> salesQuota_results{get;set;}
    public Boolean displaySearch{get;set;}
    public List<Data> Datalist{get; set;}
    public List<AggregateResult> sold_results{get;set;}
    public List<ReportsTableWrapper> wrapperList{get;set;}
    public OA_Data_Snapshots__c revenueRecord{get;set;}
    List<AggregateResult> pipeline_results{get;set;}
    
    public OA_BR_SalesGoalViewCntrl(){
        regions = OA_ReportUtility.getRegionList();
        years = OA_ReportUtility.getYearList();
        months = OA_ReportUtility.getMonthList();
        selectedRegion = 'Global';
        selectedMonth  = String.valueOf(System.today().month() -1); //'12';
        selectedYear   = String.valueOf(System.today().year());//'2017';
        search();
    }
    
    public PageReference search(){ 
		try{
            Datalist=new List<Data>();
            revenueRecord = new OA_Data_Snapshots__c();
            ReportsTableWrapper reportData;
            wrapperList = new List<ReportsTableWrapper>();
            salesQuota_results = new List<AggregateResult>();
            sold_results = new List<AggregateResult>(
                [Select OA_Region__c reg, SUM(Gross__c) totalSold 
                 FROM OA_Data_Snapshots__c 
                 WHERE OA_Year__c=: selectedYear AND Snapshot_Month__c =: selectedMonth AND OA_Probability__c = 100 
                 Group by Rollup(OA_Region__c)
                ]
            );
            
            if(Integer.valueOf(selectedYear) == System.today().year() &&
               (Integer.valueOf(selectedMonth) > System.today().month() || sold_results.size() ==0)
              ){
                  OA_Utility.addMessage('Snapshot not captured for the Selected year and month.', 'Info');
                  return null;
              }
            
           
            
            pipeline_results = new List<AggregateResult>(
                [Select OA_Region__c reg, SUM(Risk_Adjusted__c) risk
                 FROM OA_Data_Snapshots__c 
                 WHERE OA_Year__c=: selectedYear AND Snapshot_Month__c =: selectedMonth AND OA_Probability__c < 100 
                 Group by Rollup(OA_Region__c)
                ]
            );
            
                      
            List<AggregateResult> budget_results = new List<AggregateResult>(
                [SELECT SUM(OA_Total_Budget__c) total, OA_Region__c reg  
                 FROM OA_Budget__c 
                 WHERE OA_Year__c =: selectedYear
                 GROUP BY RollUp(OA_Region__c)]
            );
            
            Map<String,ReportsTableWrapper> wrapperMap = new Map<String,ReportsTableWrapper>();
            
            for(AggregateResult agr : sold_results){
                if(agr.get('reg') != null){
                    reportData = new ReportsTableWrapper(String.valueOf(agr.get('reg')),selectedMonth,selectedYear,(Double)agr.get('totalSold'));
                    wrapperMap.put(String.valueOf(agr.get('reg')),reportData);
                }
                else if(agr.get('reg') == null){
                    reportData = new ReportsTableWrapper('Global',selectedMonth,selectedYear,(Double)agr.get('totalSold'));
                    wrapperMap.put('Global',reportData);
                }
            }
            
            for(AggregateResult agr : pipeline_results){
                
                if(null != agr.get('reg') && wrapperMap.containsKey(String.valueOf(agr.get('reg')))){
                    wrapperMap.get(String.valueOf(agr.get('reg'))).Weighted_Pipeline = (Double)agr.get('risk');
                }
                else if(agr.get('reg') == null && wrapperMap.containsKey('Global')){
                    wrapperMap.get('Global').Weighted_Pipeline = (Double)agr.get('risk');
                }
            }
            Double totalSalesQuota = 0.00;
            for(AggregateResult sq : budget_results){
                if(sq.get('reg') == null && wrapperMap.containsKey('Global')){
                    wrapperMap.get('Global').Budget = (((Decimal)sq.get('total'))/1000).setScale(2);
                }
                else if(sq.get('reg') != null && wrapperMap.containsKey(String.valueOf(sq.get('reg')))){
                    wrapperMap.get(String.valueOf(sq.get('reg'))).Budget = (((Decimal)sq.get('total'))/1000).setScale(2);
                }   
            }
            for(ReportsTableWrapper rep : wrapperMap.values()){    
                rep.totalSold = rep.Sold;
                if(rep.Sold > rep.Budget){
                    rep.Surplus = (rep.Sold - rep.Budget).setScale(2);
                    rep.Gap = 0.0;
                }
                else{
                    rep.Surplus = 0.0;
                    rep.Gap = (rep.Budget - rep.Sold - rep.Weighted_Pipeline);
                }       
                if(rep.Sold > rep.Budget){
                    rep.Sold = rep.Budget;                    
                }
                if(rep.Gap < 0){
                    rep.Gap = 0.0;
                }
                wrapperList.add(rep);
                displaySearch = TRUE;
            }       
            for(ReportsTableWrapper r : wrapperList){
                   Data d = new data(r.Region, r.Sold, r.Weighted_Pipeline ,r.Budget, r.Surplus, r.Gap);
                   dataList.add(d);               
            }
            System.debug('***'+dataList);
        }
        catch(Exception ex){
            displaySearch = False; 
            OA_Utility.addMessage(ex.getMessage(), 'Error');
            System.debug('***'+ex.getMessage());
            System.debug('***'+ex.getStackTraceString());
        }
        return null;
    }
    
    public class Data {   
        public String Region { get; set; }  
        public Decimal Sold { get; set; } 
        
        public Decimal Weighted_Pipeline { get; set; }  
        public Decimal Budget { get; set; }   
        public Decimal Surplus { get; set; }   
        public Decimal Yet_To_Be_Identified { get; set; }
        public Decimal PrevSold { get; set; } 
        //add more data   
        public Data(String name, Decimal Sold,Decimal wpipeline,Decimal Budget, Decimal surplus,Decimal gap){       
            this.Region = name;       
            this.Sold = Sold; 
            this.Budget = Budget; 
            this.Weighted_Pipeline=wpipeline;
            this.Surplus=surplus;
            this.Yet_To_Be_Identified=gap;
        } 
    }
    public class ReportsTableWrapper{
        public String Region{get;set;}
        public String Month{get;set;}
        public String Year{get;set;}
        public Decimal Sold {get;set;}
        public Decimal Weighted_Pipeline{get;set;}  
        public Decimal Budget {get;set;}   
        public Decimal Surplus {get;set;}   
        public Decimal Gap {get;set;}
        public Decimal totalSold {get;set;}
        public ReportsTableWrapper(String reg, String mon, String year, Decimal totalSold){
            this.Region = reg;
            this.Month = mon;
            this.Year = year;
            this.Sold = (totalSold/1000).setScale(2);            
        }
    }
}