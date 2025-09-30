trigger OrderItemContactJsonTrigger on OrderItem (after insert, after update, after delete) {
    Set<Id> contactIds = new Set<Id>();
    Set<Id> orderIdsForFuture = new Set<Id>();
    
    // Handle insert
    if (Trigger.isInsert) {
        for (OrderItem oi : Trigger.new) {
            if (oi.OrderId != null) {
                orderIdsForFuture.add(oi.OrderId);
            }
        }
    }
    
    // Handle update
    if (Trigger.isUpdate) {
        for (OrderItem oi : Trigger.new) {
            if (oi.OrderId != null && oi.Order.BillToContactId != null) {
                contactIds.add(oi.Order.BillToContactId);
            }
        }
    }
    
    // Handle delete
    if (Trigger.isDelete) {
        for (OrderItem oi : Trigger.old) {
            if (oi.OrderId != null && oi.Order.BillToContactId != null) {
                contactIds.add(oi.Order.BillToContactId);
            }
        }
    }
    
    // Process immediate Contact IDs
    if (!contactIds.isEmpty()) {
        ContactOrderItemJsonBuilder.updateContactJson(new List<Id>(contactIds));
    }
    
    // Process Order IDs asynchronously for inserts
    if (!orderIdsForFuture.isEmpty() && !System.isFuture() && !System.isQueueable()) {
        ContactOrderItemJsonBuilder.processOrderItemsFuture(new List<Id>(orderIdsForFuture));
    }
}