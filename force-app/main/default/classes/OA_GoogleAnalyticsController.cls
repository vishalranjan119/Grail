/******************************************************************************************************
Developed By: OnActuate
Class Name:OA_GoogleAnalyticsController
Class Purpose: To parse google analytics Api
Versions: 1.1
******************************************************************************************************/
public class OA_GoogleAnalyticsController 
{
    
    public static String accesstoken{get;set;}
    
    public static void call(){
        
        http h = new Http();
        Httprequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setEndpoint('https://accounts.google.com/o/oauth2/token');
        req.setMethod('POST');
        
        req.setHeader('ContentType','application/x-www-form-urlencoded');
        
        String Header = '{"alg":"RS256","typ":"JWT"}';
        String Header_Encode = EncodingUtil.base64Encode(blob.valueof(Header));
        
        String claim_set = '{"iss":"grail-sfdc@grail-insights.iam.gserviceaccount.com"';
        claim_set += ',"scope":"https://www.googleapis.com/auth/analytics.readonly"';
        claim_set += ',"aud":"https://accounts.google.com/o/oauth2/token"';
        claim_set += ',"exp":"'+datetime.now().addHours(1).getTime()/1000;
        claim_set += '","iat":"'+datetime.now().getTime()/1000+'"}';
        
        
        
        String claim_set_Encode = EncodingUtil.base64Encode(blob.valueof(claim_set));
        
        String Singature_Encode = Header_Encode+'.'+claim_set_Encode;
        
        String key ='\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC7QtBmVefDZkdM\nRMcSFWs0oCCAp9Ni/cisDV7Aye/1Z9Kobila1p6Ih5lAM97mJNbpm6lt7P6TppGF\n8+ea1lqOeUSyBS75ePqY+0YNs+1lhGWBK36BL49SY2FXeBHn4k1R6Mgp91yhZuUO\nlO8d07ARU47By9EywDEQz2rCOJksdpFbnsEgq3kTFdyV9xQXJOHCTz/nS7xV0gr+\nnzsYZTsuLgr4ty6cU5E1SPFL6/1XmMPkOW84ntJPYRMr0cJTDl+hPO+NdsCP4VnG\n34/hHj3myymZwKO5OFcOtsCgKw+OdvippPkLQBp5hFbpxFMhXr1Mq800abEefp1z\nvypzKfztAgMBAAECggEAAhw/giMptA5Rl/NNVU+yMnQzhP+oVDPWQtNCmva964yo\nRRmouII1iOGAnOsvlnWH0xK3cmFogHxVgBQaKzsdeZK2AXpynoEez5RDEiGa95R8\nY8mzH4658MN3qsvT5Yuroa/SwaiakBFf7lJsgJSxSmnW8JeZbfJq0f8bRJx/P7OU\n3A1foiHpeaEdon300gXfLLMCWwyYE05dNXHSOd8tgeHTUBRkdvpzi+HCHfusID7C\nm6NqTG6KnWj13khC+3UktKJL/VMkH9dbmYSakPxN244kkpypCupF7nO9mEol2cYW\nNft+OO6jQI8i+9caWVxRdEvR52oq5Y+4S12AM572yQKBgQDl8OndUtche38v7DBg\nTMA3MKMs4JcQfXYDhgSK2AE5ANcMUoEVAnjC8R+qSLToscBqH+vX9TTzbtaeThpZ\nochXb7Z9K8WzATPOCxv9AYyd0pxwsT1K1t/adkIiPdsiO5F3DFey+FRQkWakgPcx\n6Nv7DORvAwD5ZCZdNYXW27d6IwKBgQDQe6jRW2fwKafD37FZ+ZcOGOMqxhqudGHK\n7eX39W5skTK7Cu5PfrMCvLopsH8jiAazDixvzV9Os7oktsBg91hlQzOjI04cqnzR\nP4GWrgw7m/TXvjHdJCR/g2BM9/Dn53evJUcQDXkkzNihoZ2594MSDgTMSSbzcIyw\nd6KM8F71rwKBgQDMc4l94Uqn2sccNUZOWfAPIo/0Nz4ay3NDbsZbLfToWnbb3gAo\nTipSK1OcdUlmHaaYtgld3AlY6hSqbYfAarlYBVydr2352/fUHMymCdqd+cZf7Tgy\ncxxXgw8KozVVGuIcmDziRSuy95Xsbz9cgVAXyT7T9jfHh+UUu6JliLd7QQKBgDDY\nuE4NB4Y6jEcVUx1MoDq6VAdCkR/Mvtjn8litVWj0gBlYz0sq2VBL3aZE5xTxGvi6\n2mh7itgKvhM6CkrtyPU40JFphTSsMUBpi7g9ITqaKLyfoFk6zZ5erqJ5+SSsk9si\ndcrqDTc1E5CTKDxZJImHZVJj1U92UFBMR3aUHvubAoGBAIWUy+kmcn8uG56IbZep\ngFh2ZDi/fG1ECOqygJExC+YIZzGHEFJZ4zQRQ/hXuE4CvRv1eXSWEhPWF+Ayi3gf\nWXLehD33BnlONa4HC+z+daclnqmBRHnKBlNl/SoXbcoCcWGRG5kzhVWo1ZvX5ppX\npgC7KLk3fHkg+lghKAhuiF1B\n';
        blob privateKey = EncodingUtil.base64Decode(key);
        Singature_Encode = Singature_Encode.replaceAll('=','');
        String Singature_Encode_Url = EncodingUtil.urlEncode(Singature_Encode,'UTF-8');
        blob Signature_b =   blob.valueof(Singature_Encode_Url);
        
        String Sinatute_blob = base64(Crypto.sign('RSA-SHA256', Signature_b , privateKey));
        
        String JWT = Singature_Encode+'.'+Sinatute_blob;
        
        JWT = JWT.replaceAll('=','');
        
        
        String grt = 'urn:ietf:params:oauth:grant-type:jwt-bearer';
        req.setBody('grant_type='+grt+'&assertion='+JWT);
        res = h.send(req);
        String Response = res.getBody() +' '+ res.getStatusCode();
        system.debug('Response ='+res.getBody() );
        JSONParser parser = JSON.createParser(res.getBody());
        
        // getting access token from response body by iteration over parser
        
        while (parser.nextToken() != null) {
            if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
                parser.nextToken();
                accesstoken=parser.getText();
            }
        }
        //system.debug('accesstoken='+accesstoken);
    }
    private static String base64(Blob b) {
        String ret = EncodingUtil.base64Encode(b);
        ret = ret.replaceAll('\\+', '-');
        ret = ret.replaceAll('/', '_');
        ret = ret.replaceAll('=', '');
        return ret;
    }
    
    
    
    public  static HttpResponse getGACount()
    {
        call();
        Http h1 = new Http();
        
        Date enddate=Date.today();
        Date startdate=enddate.addDays(1);
        string edate=string.valueOf(enddate);
        string sdate=string.valueOf(startdate);
        HttpRequest req1 = new HttpRequest();
        
        req1.setEndpoint('https://www.googleapis.com/analytics/v3/data/ga?ids=ga:178089188&dimensions=ga:Campaign,ga:keyword,ga:adContent&metrics=ga:Users,ga:sessions&start-date=yesterday&end-date=today');
        req1.setHeader('Authorization','Bearer '+accesstoken);
        req1.setHeader('ContentType','application/json; charset=UTF-8');
        
        req1.SetMethod('GET');
        HttpResponse res1=new HttpResponse();
        
        res1= h1.send(req1);
        system.debug(res1.getBody());
        if(res1.getStatusCode()==200){
            string resbody=res1.getBody();
            
            if( Resbody.contains('"rows')==true){
                parseanalyticsResponse(resbody);
            }
            
        }
        
        return res1;
        
    }
    public static  void parseanalyticsResponse(string Respbody){
        system.debug(Respbody);
        
        Map<string,string>mymap=new Map<string,string>();
        List<OA_GAnalytics__c> galist=new List<OA_GAnalytics__c>();
        OA_GResponse response1= (OA_GResponse)JSON.deserialize(Respbody,OA_GResponse.class);
        Integer i;
        if(response1.rows.size()>0){
            for(integer j=0; j<response1.rows.size();j++){
                i=0;
                for(String str:response1.rows[j]){
                    mymap.put(response1.columnHeaders[i].Name,str);    
                    ++i;
                }
                system.debug(mymap);
                List<Campaign> CmpList =[select id,Name from Campaign];
              
                for(Campaign c : CmpList )
                {
                    if((mymap.get('ga:Campaign')!='(not set)')&(mymap.get('ga:Campaign')!='(not provided)')){
                    
                          OA_GAnalytics__c ga =new OA_GAnalytics__c();
                        ga.OA_Campaign_ID__c=mymap.get('ga:Campaign');
                        ga.OA_Lead_ID__c=mymap.get('ga:keyword');
                        if(mymap.get('ga:sessions')!=Null){
                            ga.OA_Hits__c=integer.valueOf(mymap.get('ga:sessions'));}
                        ga.OA_Contact_ID__c=mymap.get('ga:adContent');                                          
                        galist.add(ga);
                    
                    }}
            }
            if(galist.size()>0){
                system.debug(galist);
                insert galist;  }}
    }
}