@IsTest
private class BA_IM_GetOrderItemTimeSlots_Test {
    @IsTest
    static void returnsTimeSlotsPerOrderItem() {
        WorkforceAcademyTestData.load();

        OrderItem unmappedItem = new OrderItem(
            OrderId = WorkforceAcademyTestData.orderId,
            PricebookEntryId = WorkforceAcademyTestData.pricebookEntryWithoutLocationId,
            Product2Id = WorkforceAcademyTestData.productWithoutLocationId,
            Quantity = 1,
            UnitPrice = 150
        );
        insert unmappedItem;

        BA_IM_GetOrderItemTimeSlots.BookingAvailabilityInput input = new BA_IM_GetOrderItemTimeSlots.BookingAvailabilityInput();
        input.orderItemIds = new List<Id>{
            WorkforceAcademyTestData.orderItemId,
            unmappedItem.Id
        };
        input.startDate = WorkforceAcademyTestData.availabilityStartDate;
        input.endDate = WorkforceAcademyTestData.availabilityStartDate.addDays(1);
        input.bookableLocationId = WorkforceAcademyTestData.bookableLocationId;

        Test.startTest();
        List<List<BA_IM_GetOrderItemTimeSlots.BookingAvailability>> responses =
            BA_IM_GetOrderItemTimeSlots.getAvailableSlots(new List<BA_IM_GetOrderItemTimeSlots.BookingAvailabilityInput>{ input });
        Test.stopTest();

        System.assertEquals(1, responses.size(), 'Expected a single batched result');
        List<BA_IM_GetOrderItemTimeSlots.BookingAvailability> availabilityGroup = responses[0];
        System.assertEquals(2, availabilityGroup.size(), 'Each order item should produce a result row');

        Boolean foundMapped = false;
        Boolean foundUnmapped = false;
        for (BA_IM_GetOrderItemTimeSlots.BookingAvailability availability : availabilityGroup) {
            if (availability.orderItem.Id == WorkforceAcademyTestData.orderItemId) {
                foundMapped = true;
                System.assert(availability.timeSlots.size() > 0, 'Mapped order item should expose time slots');
                System.assertNotEquals(true, availability.moreSlotsFound, 'Sample data should fit within the per product cap');
            }
            if (availability.orderItem.Id == unmappedItem.Id) {
                foundUnmapped = true;
                System.assertEquals(0, availability.timeSlots.size(), 'Unmapped location should return no slots');
            }
        }
        System.assert(foundMapped, 'Expected to inspect the bookable order item result');
        System.assert(foundUnmapped, 'Expected to inspect the unmapped order item result');
    }
}
