@IsTest
private class AF_IM_GetOrder_Test {
    @IsTest
    static void returnsOrderWithItems() {
        WorkforceAcademyTestData.load();

        AF_IM_GetOrder.OrderRequest request = new AF_IM_GetOrder.OrderRequest();
        request.orderId = WorkforceAcademyTestData.orderId;

        Test.startTest();
        List<AF_IM_GetOrder.OrderResponse> responses = AF_IM_GetOrder.getOrder(new List<AF_IM_GetOrder.OrderRequest>{ request });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Expected a single response row');
        AF_IM_GetOrder.OrderAndItems orderPayload = responses[0].order;
        System.assertNotEquals(null, orderPayload, 'Order payload should be populated');
        System.assertEquals(WorkforceAcademyTestData.orderId, orderPayload.orderId, 'Mismatched order id');
        System.assert(orderPayload.viewLink.contains('/account/orders/'), 'View link should reference account order URL');
        System.assertEquals(1, orderPayload.orderItems.size(), 'Should expose matching order items');
        AF_IM_GetOrder.LineItems line = orderPayload.orderItems[0];
        System.assertEquals('Bookable Product [BOOK-1001]', line.productName, 'Unexpected product name mapping');
    }
}
