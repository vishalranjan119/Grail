public class OA_Utility {
    
    public static Map<Integer, String> getMonthMap(){
        return new Map<Integer, String>{
            	1  => 'Jan',
                2  => 'Feb',
                3  => 'Mar',
                4  => 'Apr',
                5  => 'May',
                6  => 'Jun',
                7  => 'Jul',
                8  => 'Aug',
                9  => 'Sep',
                10 => 'Oct',
                11 => 'Nov',
                12 => 'Dec'
        };
    }
    
    
    public static Map<String,String> getRecordTypeInfosByName(String sObjectApiName){
        if(sObjectApiName == null || sObjectApiName == '') return null;
        Map<String, String> recordTypeInfosByName = new Map<String, String>();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.getGlobalDescribe().get(sObjectApiName).getDescribe().getRecordTypeInfosByName();
        for(String eachRT : rtMap.keyset()){
            Schema.RecordTypeInfo rtInfo = rtMap.get(eachRT);
            recordTypeInfosByName.put(rtInfo.getDeveloperName(), rtInfo.getRecordTypeId());
        }
        return recordTypeInfosByName;
    }
    
    public static void addMessage(String message, String messageType){
        if(message == null || message == '') return;
        if(messageType.equalsIgnoreCase('ERROR')) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, message));
        if(messageType.equalsIgnoreCase('INFO')) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, message));
        if(messageType.equalsIgnoreCase('FATAL')) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, message));
        if(messageType.equalsIgnoreCase('CONFIRM')) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.CONFIRM, message));
        if(messageType.equalsIgnoreCase('WARNING')) ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, message));
    }
    
    public static void handleSaveResult(){
        
    }
    
    public static void handleDeleteResult(){
        
    }
    
    public static Map<Integer, String> handleUpsertResult(List<Database.UpsertResult> results){           
        if(results == null) return null;
        Map<Integer, String> indexErrorMap = new  Map<Integer, String>();
        Integer index = 0;
        for(Database.UpsertResult result : results){
            if(result.isSuccess()) continue;
            for(Database.Error eachError : result.getErrors()){                
                addMessage(eachError.getMessage(), 'ERROR');
                indexErrorMap.put(index, eachError.getMessage());
                System.debug('Error : '+ eachError.getMessage());
            }  
            index ++ ;
        }
        return indexErrorMap;
    }

}