/**
 * Created by TetianaSakun on 08.07.2019.
 */
@IsTest
public with sharing class OpportunityLineItemServiceTest {

    @TestSetup
    public static void setup() {
        List<Product2> productsList = new List<Product2>();

        Product2 prod = new Product2(Name = 'GO Diesel 100kW', ProductCode = '452C0');
        Product2 product = new Product2(Name = 'DONE Diesel 1000kW', ProductCode = '458C0');
        productsList.add(prod);
        productsList.add(product);

        insert productsList;

        Pricebook2 customPriceBook = new Pricebook2(Name = 'CustomPriceBook');
        insert customPriceBook;

        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        PricebookEntry pricebookEntry = new PricebookEntry(Product2Id = productsList[0].Id,
                Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 5000, IsActive = true);
        PricebookEntry pricebookEntry2 = new PricebookEntry(Product2Id = productsList[1].Id,
                Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 5000, IsActive = true);
        pricebookEntryList.add(pricebookEntry);
        pricebookEntryList.add(pricebookEntry2);

        insert pricebookEntryList;
    }

    @IsTest
    public static void testSuccessChangeProduct() {
        Opportunity opportunity = new Opportunity(Name = 'Burlington Corp.', CloseDate = Date.today(),
                Pricebook2Id = Test.getStandardPricebookId(), StageName = 'Closed Won');
        insert opportunity;

        List<PricebookEntry> pricebookEntryList2 = [
                SELECT Id, Name, Product2Id
                FROM PricebookEntry
                WHERE Name = 'GO Diesel 100kW'
        ];

        List<OpportunityLineItem> opportunityLineItemsList = new List<OpportunityLineItem>();
        OpportunityLineItem oppLineItem = new OpportunityLineItem(UnitPrice = 5000, Quantity = 1,
                OpportunityId = opportunity.Id, PricebookEntryId = pricebookEntryList2[0].Id);
        opportunityLineItemsList.add(oppLineItem);

        final Id expectedDeletedId = oppLineItem.Id;

        insert opportunityLineItemsList;

        List<Product2> productList = [
                SELECT Id,Name
                FROM Product2
                WHERE Name = 'DONE Diesel 1000kW'
        ];

        List<OpportunityLineItem> opportunityLineItemListUpdate = new List<OpportunityLineItem>();

        for (OpportunityLineItem newOpportunityLineItem : opportunityLineItemsList) {
            newOpportunityLineItem.Changed_Product__c = productList[0].Id;
            opportunityLineItemListUpdate.add(newOpportunityLineItem);

        }

        Test.startTest();
        update opportunityLineItemListUpdate;
        Test.stopTest();

        System.assert([SELECT Id FROM OpportunityLineItem WHERE Id = :expectedDeletedId].isEmpty());
        System.assertEquals(1, opportunityLineItemListUpdate.size());

    }

    @IsTest
    public static void testSameProducts() {
        Opportunity opportunity = new Opportunity(Name = 'Burlington2 Corp.', CloseDate = Date.today(),
                Pricebook2Id = Test.getStandardPricebookId(), StageName = 'Closed Won');
        insert opportunity;
        List<Product2> productList = [
                SELECT Id,Name
                FROM Product2
                WHERE Name = 'GO Diesel 100kW'

        ];
        List<PricebookEntry> pricebookEntryList2 = [
                SELECT Id, Name, Product2Id
                FROM PricebookEntry
                WHERE Product2Id = :productList[0].Id
        ];

        List<OpportunityLineItem> opportunityLineItemsList = new List<OpportunityLineItem>();
        OpportunityLineItem oppLineItem = new OpportunityLineItem(UnitPrice = 5000, Quantity = 1,
                OpportunityId = opportunity.Id, PricebookEntryId = pricebookEntryList2[0].Id);
        opportunityLineItemsList.add(oppLineItem);

        insert opportunityLineItemsList;
        List<OpportunityLineItem> opportunityLineItem = [
                SELECT Id, Product2Id, UnitPrice, Quantity, OpportunityId
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunity.Id
        ];

        List<OpportunityLineItem> opportunityLineItemListUpdate = new List<OpportunityLineItem>();

        for (OpportunityLineItem newOpportunityLineItem : opportunityLineItem) {
            newOpportunityLineItem.Changed_Product__c = productList[0].Id;
            opportunityLineItemListUpdate.add(newOpportunityLineItem);

        }

        Test.startTest();
        update opportunityLineItemListUpdate;
        Test.stopTest();

        List<OpportunityLineItem> updatedOpportunityLineItems = [
                SELECT Id, Product2Id, UnitPrice, Quantity, OpportunityId
                FROM OpportunityLineItem
                WHERE OpportunityId = :opportunity.Id
        ];

        System.assertEquals(updatedOpportunityLineItems[0].Id, opportunityLineItem[0].Id);
    }

    @IsTest
    public static void testUnSuccessChangeProduct() {

        List<Pricebook2> customPriceBookList = [
                SELECT Id,Name
                FROM Pricebook2
                WHERE Name = 'CustomPriceBook'
        ];
        List<Product2> productList = [
                SELECT Id,Name
                FROM Product2
                WHERE Name = 'GO Diesel 100kW'
        ];

        Opportunity opportunity = new Opportunity(Name = 'Burlington3 Corp.', CloseDate = Date.today(),
                Pricebook2Id = customPriceBookList[0].Id, StageName = 'Closed Won');
        insert opportunity;

        Product2 newProduct2 = new Product2(Name = 'My Diesel 100kW', ProductCode = '452C048');
        insert newProduct2;

        List<PricebookEntry> pricebookEntryListWithCustomPriceBook = new List<PricebookEntry>();
        PricebookEntry pricebookEntry3 = new PricebookEntry(Product2Id = productList[0].Id,
                Pricebook2Id = customPriceBookList[0].Id, UnitPrice = 5000, IsActive = true);

        pricebookEntryListWithCustomPriceBook.add(pricebookEntry3);

        insert pricebookEntryListWithCustomPriceBook;

        List<OpportunityLineItem> opportunityLineItemsList = new List<OpportunityLineItem>();
        OpportunityLineItem oppLineItem = new OpportunityLineItem(UnitPrice = 5000, Quantity = 1,
                OpportunityId = opportunity.Id, PricebookEntryId = pricebookEntryListWithCustomPriceBook[0].Id);
        opportunityLineItemsList.add(oppLineItem);

        insert opportunityLineItemsList;

        List<OpportunityLineItem> opportunityLineItem = [
                SELECT Id, Product2Id, UnitPrice, Quantity, OpportunityId, PricebookEntryId
                FROM OpportunityLineItem
        ];

        List<OpportunityLineItem> opportunityLineItemListUpdate = new List<OpportunityLineItem>();

        for (OpportunityLineItem newOpportunityLineItem : opportunityLineItem) {
            newOpportunityLineItem.Changed_Product__c = newProduct2.Id;
            opportunityLineItemListUpdate.add(newOpportunityLineItem);
        }

        Test.startTest();

        Exception expectedException;
        try {
            update opportunityLineItemListUpdate;
        } catch (System.DmlException e) {
            expectedException = e;

            System.assertNotEquals(null, expectedException);
        }

        Test.stopTest();
    }
}