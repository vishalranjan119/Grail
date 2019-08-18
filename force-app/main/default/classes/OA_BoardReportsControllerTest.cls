@isTest
public class OA_BoardReportsControllerTest{
    public static testMethod void completeTest(){
        //Create Parent Group
        Group grp = new Group();
        grp.name = 'Execute Batch Visibility';
        grp.Type = 'Regular'; 
        Insert grp; 
 
        //Create Group Member
        GroupMember grpMem1 = new GroupMember();
        grpMem1.UserOrGroupId = UserInfo.getUserId();
        grpMem1.GroupId = grp.Id;
        Insert grpMem1;
        Test.startTest();
            OA_BoardReportsController inst = new OA_BoardReportsController();
            inst.showBatchButton = True;
            inst.executeBatch();
        Test.stopTest();    
    }
}