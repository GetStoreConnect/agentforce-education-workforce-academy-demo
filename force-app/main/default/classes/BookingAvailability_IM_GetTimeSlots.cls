public with sharing class BookingAvailability_IM_GetTimeSlots {

    public class BookingAvailabilityInput {
        @InvocableVariable(required=true)
        public Id productId;
        @InvocableVariable(required=true)
        public Date startDate;
        @InvocableVariable(required=true)
        public Date endDate;
        @InvocableVariable(required=false)
        public Id productBookableLocationId;
    }

    public class TimeSlotResult {
        @InvocableVariable public Date dateValue;
        @InvocableVariable public String bookableLocationName;
        @InvocableVariable public Id productBookableLocationId;
        @InvocableVariable public Time startTime;
        @InvocableVariable public Time endTime;
        @InvocableVariable public DateTime startsAt;
        @InvocableVariable public DateTime endsAt;
        @InvocableVariable public Integer bookingSlotsBooked;
        @InvocableVariable public Integer bookingSlotsAvailable;
        @InvocableVariable public Integer bookingSlotsTotal;
        @InvocableVariable public Boolean bookingSlotsFull;
        @InvocableVariable public Boolean unlimited;
    }

    @InvocableMethod(label='Get Booking Availability Time Slots')
    public static List<List<Booking_Availability__c >> getAvailableSlots(List<BookingAvailabilityInput> inputs) {
        List<List<Booking_Availability__c >> allResults = new List<List<Booking_Availability__c>>();

        for (BookingAvailabilityInput input : inputs) {
            // Compute slots for this single input
            List<BookingAvailabilityCalculator.DayResult> days =
                BookingAvailabilityCalculator.calculateSlots(
                    input.productId,
                    input.startDate,
                    input.endDate,
                    input.productBookableLocationId
                );

            List<Booking_Availability__c > thisResult = new List<Booking_Availability__c >();
            for (BookingAvailabilityCalculator.DayResult day : days) {
                for (BookingAvailabilityCalculator.TimeSlot slot : day.timeSlots) {
                    Booking_Availability__c  r     = new Booking_Availability__c ();
                    r.Availability_Date__c         = day.dateValue;
                    r.Name                         = day.bookableLocationName;
                    r.ProductBookableLocationId__c = day.productBookableLocationId;
                    r.StartTime__c                 = slot.startTime;
                    r.EndTime__c                   = slot.endTime;
                    r.StartsAt__c                  = slot.startsAt;
                    r.EndsAt__c                    = slot.endsAt;
                    r.BookingSlotsBooked__c        = slot.bookingSlotsBooked;
                    r.BookingSlotsAvailable__c     = slot.bookingSlotsAvailable;
                    //r.bookingSlotsTotal         = slot.bookingSlotsTotal;
                    //r.bookingSlotsFull          = slot.bookingSlotsFull;
                    r.Unlimited__c                 = slot.unlimited;
                    thisResult.add(r);
                }
            }
            allResults.add(thisResult);
        }

        return allResults;
    }
}