public class OA_BoardReportsController {
    public Boolean showBatchButton{get;set;}
    public OA_BoardReportsController(){
        Id loggedInUserId = UserInfo.getUserId();
        Group g = [SELECT id, Name, (SELECT Id, UserOrGroupId FROM GroupMembers WHERE UserOrGroupId =: loggedInUserId) FROM Group WHERE DeveloperName = 'Execute_Batch_Visibility'];
        if(g.GroupMembers.size() > 0){
            showBatchButton = TRUE;
        }else{
            showBatchButton = FALSE;
        }
    }
    public void executeBatch(){
        OA_SnapshotsBatch runBatch = new OA_SnapshotsBatch();
        Database.executeBatch(runBatch,200);
        showBatchButton = FALSE;
    }
}