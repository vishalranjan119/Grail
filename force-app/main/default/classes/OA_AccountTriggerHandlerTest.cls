@isTest
public class OA_AccountTriggerHandlerTest{
    @isTest public static void main(){
        Account a = new Account(name = 'abc');
        insert a;
        Profile pf= [Select Id from profile where Name='Grail - Sales User']; 
        User uu=new User(firstname = 'ABC', 
                        lastName = 'XYZ', 
                        email = 'abc@test.com', 
                        alias = 'pop',
                        Username = 'abc@test.trial', 
                        EmailEncodingKey = 'ISO-8859-1',  
                        TimeZoneSidKey = 'America/Los_Angeles', 
                        LocaleSidKey = 'en_US', 
                        LanguageLocaleKey = 'en_US', 
                        ProfileId = pf.Id); 
        Test.startTest();
            System.runAs(uu){
                try{
                    delete a;
                }    
                catch(Exception ex){
                    
                }
            }        
        Test.stopTest();
    }
}