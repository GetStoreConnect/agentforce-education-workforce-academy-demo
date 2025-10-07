@IsTest
private class BookingAvailabilityInvocables_Test {
    @IsTest
    static void getTimeSlotsReturnsStructuredRows() {
        WorkforceAcademyTestData.load();

        
        BookingAvailability_IM_GetTimeSlots.BookingAvailabilityInput input = new BookingAvailability_IM_GetTimeSlots.BookingAvailabilityInput();
        input.productId = WorkforceAcademyTestData.productId;
        input.startDate = WorkforceAcademyTestData.availabilityStartDate;
        input.endDate = WorkforceAcademyTestData.availabilityStartDate.addDays(1);
        input.productBookableLocationId = WorkforceAcademyTestData.productBookableLocationId;

        Test.startTest();
        List<List<Booking_Availability__c>> payload = BookingAvailability_IM_GetTimeSlots.getAvailableSlots(
            new List<BookingAvailability_IM_GetTimeSlots.BookingAvailabilityInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, payload.size(), 'Expected a single wrapper list');
        System.assert(payload[0].size() > 0, 'Time slots should be converted into booking availability rows');
        Booking_Availability__c row = payload[0][0];
        System.assertNotEquals(null, row.Name, 'Location label should be populated');
        System.assertNotEquals(null, row.StartTime__c, 'Start time should be populated');
    }

    @IsTest
    static void getHighlightsReturnsDates() {
        WorkforceAcademyTestData.load();

        BookingAvailability_IM_GetHighlightTimes.BookingAvailabilityInput input = new BookingAvailability_IM_GetHighlightTimes.BookingAvailabilityInput();
        input.productId = WorkforceAcademyTestData.productId;
        input.startDate = WorkforceAcademyTestData.availabilityStartDate;
        input.endDate = WorkforceAcademyTestData.availabilityStartDate.addDays(1);
        input.productBookableLocationId = WorkforceAcademyTestData.productBookableLocationId;

        List<List<BookingAvailability_IM_GetHighlightTimes.DateHighlightResult>> response =
            BookingAvailability_IM_GetHighlightTimes.getHighlightDates(
                new List<BookingAvailability_IM_GetHighlightTimes.BookingAvailabilityInput>{ input }
            );

        System.assertEquals(1, response.size(), 'Expected a single batched result');
        System.assert(response[0].size() > 0, 'Highlight list should contain at least one date');
        System.assertEquals(
            WorkforceAcademyTestData.availabilityStartDate,
            response[0][0].highlightDate,
            'Highlight date should echo the availability returned by the calculator'
        );
    }
}
