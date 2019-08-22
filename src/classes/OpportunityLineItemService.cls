/* Created by TetianaSakun on 04.07.2019.*/


public with sharing class OpportunityLineItemService {


/*Execution of creating new records*/

    public void createNewOpportunityLineItemAfterUpdate(List<OpportunityLineItem> oppLineItem) {

        //OPPORTUNITY LINE ITEM
        List<OpportunityLineItem> changedLineItems = this.filterChangedLineItems(oppLineItem);
        if (changedLineItems.isEmpty()) {
            return;
        }
        Map<Id, Id> priceBookIdsByOppIds = getPriceBookIdsByOppIds(changedLineItems);
        //OPPORTUNITY LINE ITEM


        //PRICEBOOK ENTRIES
        Set<Id> changedProductsIds = this.getProductsIds(changedLineItems);
        Map<String, PricebookEntry> productsWithPricebookEntries =
                this.getPriceBookEntriesByCompoundKey(changedProductsIds, priceBookIdsByOppIds.values());


        List<OpportunityLineItem> opportunityLineItemForUpdate =
                this.getClonedOpportunityLineItem(changedLineItems, priceBookIdsByOppIds, productsWithPricebookEntries);


        insert opportunityLineItemForUpdate;
        delete changedLineItems.deepClone(true);

    }

    private List<OpportunityLineItem> filterChangedLineItems(List<OpportunityLineItem> oppLineItem) {
        List<OpportunityLineItem> result = new List<OpportunityLineItem>();
        for (OpportunityLineItem newOpportunityLineItem : oppLineItem) {
            if (newOpportunityLineItem.Changed_Product__c != null &&
                    newOpportunityLineItem.Product2Id != newOpportunityLineItem.Changed_Product__c) {
                result.add(newOpportunityLineItem);
            }
        }
        System.debug('result ' + result);
        return result;
    }


/* Getting information to next using*/


    private Set<Id> getProductsIds(List<OpportunityLineItem> oppLineItemsList) {
        Set<Id> changedProdIds = new Set<Id>();
        for (OpportunityLineItem oppLineItem : oppLineItemsList) {
            changedProdIds.add(oppLineItem.Changed_Product__c);
        }

        return changedProdIds;
    }

    private Map<String, PricebookEntry> getPriceBookEntriesByCompoundKey
            (Set<Id> changedProdIds, List<Id> priceBookIds) {
        List<PricebookEntry> pricebookEntries = [
                SELECT Name, Pricebook2Id, Product2Id, UnitPrice
                FROM PricebookEntry
                WHERE Product2Id IN:changedProdIds
                AND Pricebook2Id IN:priceBookIds
        ];
        Map<String, PricebookEntry> productsWithPricebookEntriesByCompoundKey = new Map<String, PricebookEntry>();

        for (PricebookEntry pricebookEntry : pricebookEntries) {
            productsWithPricebookEntriesByCompoundKey.put(this.createCompoundKey
                    (pricebookEntry.Product2Id, pricebookEntry.Pricebook2Id), pricebookEntry);
        }

        return productsWithPricebookEntriesByCompoundKey;
    }

    private String createCompoundKey(Id productId, Id priceBookId) {
        return '' + productId + '.' + priceBookId;
    }

    private Map<Id, Id> getPriceBookIdsByOppIds(List<OpportunityLineItem> opportunityLineItems) {
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem opportunityLineItem : opportunityLineItems) {
            oppIds.add(opportunityLineItem.OpportunityId);
        }
        List<Opportunity> opportunities = [
                SELECT Id, Pricebook2Id
                FROM Opportunity
                WHERE Id IN:oppIds
        ];

        Map<Id, Id> opportunityWithPriceBooksIds = new Map<Id, Id>();
        for (Opportunity opportunity : opportunities) {
            opportunityWithPriceBooksIds.put(opportunity.Id, opportunity.Pricebook2Id);
        }

        return opportunityWithPriceBooksIds;
    }

    private List<OpportunityLineItem> getClonedOpportunityLineItem(List<OpportunityLineItem> changedLineItems,
            Map<Id, Id> priceBookIdsByOppIds,
            Map<String, PricebookEntry> productsWithPricebookEntries) {

        List<OpportunityLineItem> result = new List<OpportunityLineItem>();


        for (OpportunityLineItem opportunityLineItem : changedLineItems) {
            Id pricebookId = priceBookIdsByOppIds.get(opportunityLineItem.OpportunityId);
            String compoundKey = this.createCompoundKey(opportunityLineItem.Changed_Product__c, pricebookId);
            if (!productsWithPricebookEntries.containsKey(compoundKey)) {
                throw new OpportunityLineItemServiceException('No applicable Price Book Entry for this Product');
            }
            PricebookEntry pricebookEntry = productsWithPricebookEntries.get(compoundKey);

            OpportunityLineItem newOpportunityLineItem = opportunityLineItem.clone(false, true);
            newOpportunityLineItem.PricebookEntryId = pricebookEntry.Id;
            newOpportunityLineItem.TotalPrice = null;

            result.add(newOpportunityLineItem);
        }

        return result;
    }

    public class OpportunityLineItemServiceException extends Exception {
    }
}