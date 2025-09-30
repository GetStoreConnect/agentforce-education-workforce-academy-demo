global with sharing class AF_IM_GetOrders {
    @InvocableMethod(label='Get Orders List' description='Retrieves a list of orders or a single order with items')
    global static List<OrdersResponse> getOrders(List<Request> requests) {
        List<OrdersResponse> results = new List<OrdersResponse>();
        String baseUrl = 'https://00dfl000003pbbrea4-78590c2f.storeconnect.app';
        
        for (Request req : requests) {
            OrdersResponse resp = new OrdersResponse();
            resp.orders = new List<OrderResponse>();
            
            List<Order> sfOrders;
            sfOrders = [
                        SELECT Id, OrderNumber, EffectiveDate, Status, TotalAmount, s_c__Store_Id__r.s_c__Domain__c,
                        (SELECT Id, Product2Id, ProductName__c, Product2.s_c__Slug__c, Quantity, TotalPrice, Bookable_Status__c, Booking_Info__c FROM OrderItems)
                        FROM Order WHERE s_c__Contact_Id__c = :req.contactId AND s_c__Store_Id__c = :req.storeId Order BY EffectiveDate Desc
            ];

            
            for (Order o : sfOrders) {
                OrderResponse orsp = new OrderResponse();
                orsp.orderId = o.Id;
                orsp.orderNumber = o.OrderNumber;
                orsp.orderDate = o.EffectiveDate;
                orsp.status = o.Status;
                orsp.totalAmount = Integer.ValueOf(o.TotalAmount);
                orsp.numItems = o.OrderItems.size();
                orsp.viewLink = 'https://'+ o.s_c__Store_Id__r.s_c__Domain__c + '/account/orders/' + o.OrderNumber;
                orsp.items = new List<OrderItemResponse>();
                
                for (OrderItem oi : o.OrderItems) {
                    OrderItemResponse irsp = new OrderItemResponse();
                    irsp.productName = oi.ProductName__c; 
                    irsp.productLink = 'https://'+ o.s_c__Store_Id__r.s_c__Domain__c + '/products/' + oi.Product2.s_c__Slug__c ;
                    irsp.product2Id = oi.Product2Id;
                    irsp.quantity = Integer.ValueOf(oi.Quantity);
                    irsp.lineAmount = Integer.ValueOf(oi.TotalPrice);
                    if (oi.Bookable_Status__c != 'Not Bookable') {
                irsp.bookingInfo = oi.Booking_Info__c;
                    }
                    orsp.items.add(irsp);
                }
                resp.orders.add(orsp);
            }
            results.add(resp);
        }
        return results;
    }
    
    global class Request {
        @InvocableVariable global String contactId;
        @InvocableVariable global String storeId;
    }
    
    global class OrdersResponse {
        @InvocableVariable global List<OrderResponse> orders;
    }
    
    global class OrderResponse {
        @InvocableVariable global String orderId;
        @InvocableVariable global String orderNumber;
        @InvocableVariable global Date orderDate;
        @InvocableVariable global String status;
        @InvocableVariable global Integer numItems;
        @InvocableVariable global Integer totalAmount;
        @InvocableVariable global List<OrderItemResponse> items;
        @InvocableVariable global String viewLink;
    }
    
    global class OrderItemResponse {
        @InvocableVariable global String productName;
        @InvocableVariable global String product2Id;
        @InvocableVariable global String productLink;
        @InvocableVariable global Integer quantity;
        @InvocableVariable global Integer lineAmount;
        @InvocableVariable global String bookingInfo;
    }
}