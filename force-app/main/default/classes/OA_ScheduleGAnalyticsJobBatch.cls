/******************************************************************************************************
Developed By: OnActuate
Class Name: OA_ScheduleGAnalyticsJob
Class Purpose: Schedule Job for Google Analytics Job
Versions: 1.1
******************************************************************************************************/
public class OA_ScheduleGAnalyticsJobBatch implements schedulable{
    
    public void execute(SchedulableContext SC) {
      System.enqueueJob(new OA_ExampleQueueable());
         
   }

}