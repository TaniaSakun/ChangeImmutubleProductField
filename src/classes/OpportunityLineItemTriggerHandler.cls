/**
 * Created by TetianaSakun on 04.07.2019.
 */

public with sharing class OpportunityLineItemTriggerHandler {
    public static void afterUpdate(List<OpportunityLineItem> oppLineItem) {
        new OpportunityLineItemService().createNewOpportunityLineItemAfterUpdate(oppLineItem);
    }

}