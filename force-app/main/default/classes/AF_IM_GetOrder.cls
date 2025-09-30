public with sharing class AF_IM_GetOrder {
    @InvocableMethod(label='Get Order' description='Get\'s and order with order line items')
    public static List<OrderResponse> getOrder(List<OrderRequest> requests) {
		List<OrderResponse> orderResponses = new List<OrderResponse>();
        
        for (OrderRequest req : requests) {
            OrderResponse resp = new OrderResponse();

            List<Order> sfOrders;
            sfOrders = [ 
                        SELECT Id, OrderNumber, EffectiveDate, Status, TotalAmount, s_c__Payment_Link__c, s_c__Store_Id__r.s_c__Domain__c,
                        (SELECT Id, Product2Id, ProductName__c, Product2.s_c__Slug__c, Quantity, TotalPrice, Bookable_Status__c, Booking_Info__c FROM OrderItems)
                        FROM Order WHERE Id =:req.orderId Order BY EffectiveDate Desc Limit 1
            ];

            if(sfOrders.isEmpty()){
                return null;
            }

            
            for (Order o : sfOrders) {
                OrderAndItems orsp = new OrderAndItems();
                orsp.orderId = o.Id;
                orsp.orderNumber = o.OrderNumber;
                orsp.orderDate = o.EffectiveDate;
                orsp.status = o.Status;
                orsp.paymentLink = o.Status == 'Draft' ? o.s_c__Payment_Link__c : 'Paid';
                orsp.totalAmount = Integer.ValueOf(o.TotalAmount);
                orsp.numItems = o.OrderItems.size();
                orsp.viewLink = 'https://'+ o.s_c__Store_Id__r.s_c__Domain__c + '/account/orders/' + o.OrderNumber;
                orsp.orderItems = new List<LineItems>();
                
                for (OrderItem oi : o.OrderItems) {
                    LineItems irsp = new LineItems();
                    irsp.orderItemId = oi.Id;
                    irsp.productName = oi.ProductName__c;
                    irsp.product2Id = oi.Product2Id;
                    irsp.productLink = 'https://'+ o.s_c__Store_Id__r.s_c__Domain__c + '/products/' + oi.Product2.s_c__Slug__c ;
                    irsp.quantity = Integer.ValueOf(oi.Quantity);
                    irsp.lineAmount = Integer.ValueOf(oi.TotalPrice);
                    if (oi.Bookable_Status__c != 'Not Bookable') {
                      irsp.bookingInfo = oi.Booking_Info__c; 
                    }
                    orsp.orderItems.add(irsp);
                }
                resp.order = orsp;
            }
            orderResponses.add(resp);
        }

        return orderResponses;
    }
    public class OrderRequest {

        @InvocableVariable
        public String orderId;

    }

    public class OrderResponse {
        @InvocableVariable
        public OrderAndItems order;
    }

    public class OrderAndItems {
        @InvocableVariable
        public String orderId;
        @InvocableVariable 
        public String orderNumber;
        @InvocableVariable 
        public Date orderDate;
        @InvocableVariable 
        public String status;
        @InvocableVariable 
        public Integer numItems;
        @InvocableVariable 
        public Integer totalAmount;
        @InvocableVariable 
        public String viewLink;
        @InvocableVariable 
        public String paymentLink;
        public List<LineItems> orderItems;
    }

    public class LineItems {
        @InvocableVariable public String orderItemId;
        @InvocableVariable public String product2Id;
        @InvocableVariable public String productName;
        @InvocableVariable public String productLink;
        @InvocableVariable public Integer quantity;
        @InvocableVariable public Integer lineAmount;
        @InvocableVariable public String bookingInfo;
    }


}