public class OA_AccountTriggerHandler{
    public static void beforeDelete(List<Account> oldList){
        Profile p = [SELECT id, name FROM Profile WHERE Name = 'System Administrator'];
        for(Account a : oldList){
            if(UserInfo.getProfileId() <> p.id){
                a.addError('You do not have the access to delete Account records. Kindly contact your System Admin for further assistance.');
            }    
        }
    }
}