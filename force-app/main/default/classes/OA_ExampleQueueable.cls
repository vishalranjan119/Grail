/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_ExampleQueueable
Class Purpose: Queueable class to run the Google Analytics syn job
Versions: 1.1
*****************************************************************************************************/
public class OA_ExampleQueueable implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        OA_GoogleAnalyticsController.getGACount();
    }
}