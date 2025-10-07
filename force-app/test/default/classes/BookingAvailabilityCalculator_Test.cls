@IsTest
private class BookingAvailabilityCalculator_Test {
    @IsTest
    static void calculatesSlotsAndHighlights() {
        WorkforceAcademyTestData.load();

        List<BookingAvailabilityCalculator.DayResult> dayResults =
            BookingAvailabilityCalculator.calculateSlots(
                WorkforceAcademyTestData.productId,
                WorkforceAcademyTestData.availabilityStartDate,
                WorkforceAcademyTestData.availabilityStartDate.addDays(1),
                WorkforceAcademyTestData.productBookableLocationId
            );

        System.assert(dayResults.size() > 0, 'Expected at least one day of availability');
        BookingAvailabilityCalculator.DayResult sampleDay = dayResults[0];
        System.assertEquals(WorkforceAcademyTestData.productBookableLocationId, sampleDay.productBookableLocationId);
        System.assert(sampleDay.timeSlots.size() > 0, 'Time slots should be generated for the configured availability');
        BookingAvailabilityCalculator.TimeSlot slot = sampleDay.timeSlots[0];
        System.assertNotEquals(null, slot.startTime, 'Slot start time should be populated');
        System.assertEquals('GMT', slot.locationTimezone, 'Timezone should mirror the configured bookable location');

        Set<Date> highlights = BookingAvailabilityCalculator.calculateHighlights(
            WorkforceAcademyTestData.productId,
            WorkforceAcademyTestData.availabilityStartDate,
            WorkforceAcademyTestData.availabilityStartDate,
            WorkforceAcademyTestData.productBookableLocationId
        );
        System.assert(highlights.contains(WorkforceAcademyTestData.availabilityStartDate), 'Highlight set should include the booking date');

        // Guard against null inputs returning data unexpectedly
        System.assertEquals(0, BookingAvailabilityCalculator.calculateSlots(null, null, null, null).size(), 'Null inputs should short-circuit to empty results');
        System.assertEquals(0, BookingAvailabilityCalculator.calculateHighlights(null, null, null, null).size(), 'Null inputs should not produce highlight dates');
    }
}
