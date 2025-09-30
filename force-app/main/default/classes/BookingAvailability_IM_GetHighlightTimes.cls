public class BookingAvailability_IM_GetHighlightTimes {

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

    public class DateHighlightResult {
        @InvocableVariable public Date highlightDate;
    }

    @InvocableMethod(label='Get Booking Availability Highlight Dates')
    public static List<List<DateHighlightResult>> getHighlightDates(List<BookingAvailabilityInput> inputs) {
        List<List<DateHighlightResult>> allResults = new List<List<DateHighlightResult>>();

        for (BookingAvailabilityInput input : inputs) {
            Set<Date> highlights = BookingAvailabilityCalculator.calculateHighlights(
                input.productId,
                input.startDate,
                input.endDate,
                input.productBookableLocationId
            );

            List<DateHighlightResult> thisResult = new List<DateHighlightResult>();
            for (Date d : highlights) {
                DateHighlightResult r = new DateHighlightResult();
                r.highlightDate = d;
                thisResult.add(r);
            }
            allResults.add(thisResult);
        }

        return allResults;
    }
}