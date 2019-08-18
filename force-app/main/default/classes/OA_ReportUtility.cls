public class OA_ReportUtility {
    public static Decimal getYearEndRevenue(String year, String region, String month){
        String baseQuery = 'SELECT SUM(Gross__c) FROM OA_Data_Snapshots__c';
        String whereClouse =' WHERE OA_Probability__c = 100 AND OA_Year__c =\''+year+'\' AND Snapshot_Month__c = \''+month+'\'';
        if(region != null && region != 'Global'){
            whereClouse += ' AND OA_Region__c=\''+region+'\'';
        }
        String query = baseQuery + whereClouse;
        System.debug('query:'+query);
        List<AggregateResult> results = new List<AggregateResult>(
            (List<AggregateResult>)Database.query(query)
        );
        if(results == null || results.isEmpty()) return 0;
        return (Decimal)results[0].get('expr0');      
    }
    
    public static Decimal getYearEndRevenue(String year, String region){
        String baseQuery = 'SELECT SUM(Gross__c) FROM OA_Data_Snapshots__c';
        String whereClouse =' WHERE OA_Probability__c = 100 AND OA_Year__c =\''+year+'\' AND Snapshot_Month__c = \'12\'';
        if(region != null && region != 'Global'){
            whereClouse += ' AND OA_Region__c=\''+region+'\'';
        }
        String query = baseQuery + whereClouse;
        System.debug('query:'+query);
        List<AggregateResult> results = new List<AggregateResult>(
            (List<AggregateResult>)Database.query(query)
        );
        if(results == null || results.isEmpty()) return 0;
        return (Decimal)results[0].get('expr0');      
    }
    
    public static Decimal getYearEndBudget(String year, String region){
        String baseQuery = 'SELECT SUM(OA_Total_Budget__c) FROM OA_Budget__c';
        String whereClouse =' WHERE OA_Year__c =\''+year+'\'';
        if(region != null && region != 'Global'){
            whereClouse += ' AND OA_Region__c=\''+region+'\'';
        }
        String query = baseQuery + whereClouse;
        List<AggregateResult> results = new List<AggregateResult>(
            (List<AggregateResult>)Database.query(query)
        );
        if(results == null || results.isEmpty()) return 0;
        return (Decimal)results[0].get('expr0');   
 
    }
    
    public static List<SelectOption> getRegionList() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Global','Global'));
        options.add(new SelectOption('Europe','Europe'));
        options.add(new SelectOption('East NA','East NA'));
        options.add(new SelectOption('West NA','West NA'));
        options.add(new SelectOption('APAC & MEA','APAC & MEA'));
        return options;
    }
    
    public static List<SelectOption> getYearList(){
        Integer currentYear = System.today().year();
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(String.valueOf(currentYear),String.valueOf(currentYear)));
        options.add(new SelectOption(String.valueOf(currentYear-1),String.valueOf(currentYear-1)));
        options.add(new SelectOption(String.valueOf(currentYear-2),String.valueOf(currentYear-2)));
        options.add(new SelectOption(String.valueOf(currentYear-3),String.valueOf(currentYear-3)));
        return options;
    }
    
    public static Map<String, String> getMonthMap(){
        Map<String, String> monthMap = new Map<String, String>();
        monthMap.put('12','December');
        monthMap.put('11','November');
        monthMap.put('10','October');
        monthMap.put('9','September');
        monthMap.put('8','August');
        monthMap.put('7','July');
        monthMap.put('6','June');
        monthMap.put('5','May');
        monthMap.put('4','April');
        monthMap.put('3','March');
        monthMap.put('2','February');
        monthMap.put('1','January');
        return monthMap;       
    }
    
    public static List<SelectOption> getMonthList(){
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('1','January'));
        options.add(new SelectOption('2','February'));
        options.add(new SelectOption('3','March'));
        options.add(new SelectOption('4','April'));
        options.add(new SelectOption('5','May'));
        options.add(new SelectOption('6','June'));
        options.add(new SelectOption('7','July'));
        options.add(new SelectOption('8','August'));
        options.add(new SelectOption('9','September'));
        options.add(new SelectOption('10','October'));
        options.add(new SelectOption('11','November'));
        options.add(new SelectOption('12','December'));
        return options;
    }
    
    public static Map<String, Map<String, Decimal>> getRegionlQuotaByMonth(String year){
        if(year == null || year == '') return null;
        Map<String, Map<String, Decimal>> regionalMonthlyBudget = new Map<String, Map<String, Decimal>>();
        Map<String,String> monthMap = getMonthMap();
        List<AggregateResult> budgetResults = new List<AggregateResult>(
            [select OA_Budget__r.OA_Region__c region, SUM(January__c), SUM(February__c), SUM(March__c), SUM(April__c),SUM(May__c),SUM(June__c),SUM(July__c),SUM(August__c),SUM(September__c),SUM(October__c),SUM(November__c),SUM(December__c) FROM OA_Monthly_Budget__c 
             WHERE OA_Budget__r.OA_Year__c =:year 
             Group By Rollup(OA_Budget__r.OA_Region__c)
            ]
        );
        for(AggregateResult result : budgetResults){
            String region = (String)result.get('region');
            if(!regionalMonthlyBudget.containsKey(region)) regionalMonthlyBudget.put(region, new Map<String, Decimal>());
            for(Integer i=0; i<12; i++){
                String expr = 'expr'+String.valueOf(i);
                regionalMonthlyBudget.get(region).put(monthMap.get(String.valueOf(i+1)), (Decimal)result.get(expr));
            }
        }
        
        /*for(OA_Monthly_Quota__c mq : [SELECT OA_Sales_Target__r.OA_Region__c, OA_Month__c, OA_Monthly_Quota__c FROM OA_Monthly_Quota__c WHERE OA_Sales_Target__r.RecordType.DeveloperName = 'Regional_Target' AND OA_Year__c=: year]){
            if(!regionalMonthlyBudget.containsKey(mq.OA_Sales_Target__r.OA_Region__c)){
                regionalMonthlyBudget.put(mq.OA_Sales_Target__r.OA_Region__c, new Map<String, Decimal>());
            }
            regionalMonthlyBudget.get(mq.OA_Sales_Target__r.OA_Region__c).put(monthMap.get(mq.OA_Month__c), mq.OA_Monthly_Quota__c);
        }*/
        return regionalMonthlyBudget;
    }
    
}