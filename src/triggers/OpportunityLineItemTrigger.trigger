/**
 * Created by TetianaSakun on 04.07.2019.
 */

trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            OpportunityLineItemTriggerHandler.afterUpdate(Trigger.new);
        }
    }
}