@IsTest
private class AF_IM_GetOrders_Test {
    @IsTest
    static void returnsOrdersForContactAndStore() {
        WorkforceAcademyTestData.load();

        AF_IM_GetOrders.Request request = new AF_IM_GetOrders.Request();
        request.contactId = String.valueOf(WorkforceAcademyTestData.contactId);
        request.storeId = String.valueOf(WorkforceAcademyTestData.storeId);

        Test.startTest();
        List<AF_IM_GetOrders.OrdersResponse> responses = AF_IM_GetOrders.getOrders(new List<AF_IM_GetOrders.Request>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Expected single batched response');
        System.assert(responses[0].orders.size() >= 1, 'At least one order should be returned');

        AF_IM_GetOrders.OrderResponse first = responses[0].orders[0];
        System.assertNotEquals(null, first.orderId, 'First order should expose an id');
        System.assert(first.viewLink.contains('/account/orders/'), 'View link should surface storefront path');
        if (!first.items.isEmpty()) {
            System.assertEquals('Bookable Product', first.items[0].productName, 'Product name should map from order item');
        }

        // Exercise no-match scenario to ensure graceful handling
        AF_IM_GetOrders.Request noMatch = new AF_IM_GetOrders.Request();
        noMatch.contactId = '003000000000000AAA';
        noMatch.storeId = String.valueOf(WorkforceAcademyTestData.storeId);

        List<AF_IM_GetOrders.OrdersResponse> noOrders = AF_IM_GetOrders.getOrders(new List<AF_IM_GetOrders.Request>{ noMatch });
        System.assertEquals(1, noOrders.size(), 'Expected batched response for unmatched request');
        System.assertEquals(0, noOrders[0].orders.size(), 'Unexpected orders returned for unrelated contact');
    }
}
