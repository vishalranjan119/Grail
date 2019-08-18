/******************************************************************************************************
Developed By: OnActuate
Class Name:OA_AnalyticsCalloutMock 
Class Purpose: Mockout for Analytics HTTP Callout
Versions: 1.1
******************************************************************************************************/
@isTest
global class OA_AnalyticsCalloutMock  implements HttpCalloutMock {

    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setBody('{"kind":"analytics#gaData","id":"https://www.googleapis.com/analytics/v3/data/ga?ids=ga:178089188&dimensions=ga:Campaign,ga:keyword,ga:adContent&metrics=ga:Users,ga:sessions&start-date=yesterday&end-date=today","query":{"start-date":"yesterday","end-date":"today","ids":"ga:178089188","dimensions":"ga:Campaign,ga:keyword,ga:adContent","metrics":["ga:Users","ga:sessions"],"start-index":1,"max-results":1000},"itemsPerPage":1000,"totalResults":9,"selfLink":"https://www.googleapis.com/analytics/v3/data/ga?ids=ga:178089188&dimensions=ga:Campaign,ga:keyword,ga:adContent&metrics=ga:Users,ga:sessions&start-date=yesterday&end-date=today","profileInfo":{"profileId":"178089188","accountId":"121774600","webPropertyId":"UA-121774600-1","internalWebPropertyId":"179860202","profileName":"All Web Site Data","tableId":"ga:178089188"},"containsSampledData":false,"columnHeaders":[{"name":"ga:Campaign","columnType":"DIMENSION","dataType":"STRING"},{"name":"ga:keyword","columnType":"DIMENSION","dataType":"STRING"},{"name":"ga:adContent","columnType":"DIMENSION","dataType":"STRING"},{"name":"ga:Users","columnType":"METRIC","dataType":"INTEGER"},{"name":"ga:sessions","columnType":"METRIC","dataType":"INTEGER"}],"totalsForAllResults":{"ga:Users":"147","ga:sessions":"188"},"rows":[["(not set)","(not provided)","(not set)","85","103"],["(not set)","(not set)","(not set)","55","77"],["(not set)","grail insights","(not set)","1","2"],["7010k000000duTf","(not set)","0030k00000lPK2z","1","1"],["7010k000000duTf","(not set)","0030k00000lPKEW","1","1"],["7010k000000duTf","00Q0k000006tgdN","(not set)","1","1"],["7010k000000duTf","00Q0k000006tgxp","(not set)","1","1"],["7010k000000duz9","(not set)","0030k00000lPKEW","1","1"],["7010k000000duz9","00Q0k000006tgdN","(not set)","1","1"]]}');
        response.setStatusCode(200);
        return response; 
    }
}