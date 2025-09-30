public with sharing class BA_IM_GetOrderItemTimeSlots {
	Private static final Integer maxSlotsTotal = 40;
    public class BookingAvailabilityInput {
        @InvocableVariable(required=true description='List of OrderItem IDs for which to fetch booking availabilities. Each OrderItem must be associated with a bookable Product2.')
        public List<Id> orderItemIds;
        @InvocableVariable(required=true description='The start date for searching slots, in YYYY-MM-DD format (e.g., \'2025-07-19\'). Must be a future date and before or equal to untilDate; if past or invalid, action may return empty—prompt user for future dates.')
        public Date startDate;
        @InvocableVariable(required=true description='The end date for searching slots, in YYYY-MM-DD format (e.g., \'2025-08-19\'). Must be a future date and after or equal to fromDate; extend range if no slots found.')
        public Date endDate;
        @InvocableVariable(required=false description='Optional: The 18-character alphanumeric ID of the specific Bookable Location to filter availabilities. Omit this input entirely if no specific location is selected by the user. If provided, it must be a valid Salesforce ID (starting with appropriate prefix, e.g., a0A for custom objects). If not provided, availabilities for all locations will be returned.')
        public Id bookableLocationId;
    }

    public class TimeSlotResult {
        @InvocableVariable(description='The date of the availability slot.')
        public Date dateValue;
        @InvocableVariable(description='The name of the bookable location.')
        public String bookableLocationName;
        @InvocableVariable(description='The ID of the BookableLocation.')
        public Id productBookableLocationId;
        @InvocableVariable(description='The start time of the slot.')
        public Time startTime;
        @InvocableVariable(description='The end time of the slot.')
        public Time endTime;
      /*@InvocableVariable(description='The start DateTime of the slot.')
        public DateTime startsAt;*/
      /*@InvocableVariable(description='The end DateTime of the slot.')
        public DateTime endsAt;*/
        @InvocableVariable(description='Number of booking slots already booked.')
        public Integer bookingSlotsBooked;
        @InvocableVariable(description='Number of booking slots still available.')
        public Integer bookingSlotsAvailable;
        @InvocableVariable(description='Total number of booking slots.')
        public Integer bookingSlotsTotal;
        @InvocableVariable(description='Whether the booking slots are full.')
        public Boolean bookingSlotsFull;
        @InvocableVariable(description='Whether the slots are unlimited.')
        public Boolean unlimited;
        @InvocableVariable(description='The Timezone of the booking slot.')
        public String locationTimezone;
    }

    public class BookingAvailability {
        @InvocableVariable(description='The OrderItem record corresponding to the availability.')
        public OrderItem orderItem;
        @InvocableVariable(description='List of available time slots for the product of this OrderItem.')
        public List<TimeSlotResult> timeSlots;
        @InvocableVariable(description='Indicates there are more timeslots found than returned for the given filters.')
        public boolean moreSlotsFound;
    }

    @InvocableMethod(
        label='Get Booking Availability Time Slots for Order Items'
        description='Retrieves booking availability time slots for the products associated with the given OrderItem IDs within the specified date range. Optionally, filter by a specific bookable location. Use this action when the user needs to view or select available time slots for booking products in their order, such as scheduling events or appointments. This action processes multiple OrderItems, computing slots based on their linked Product2 records. Ensure the products are confirmed bookable before invoking this action. If a specific bookableLocationId is provided, only slots at that location will be returned if the product is available there; otherwise, empty slots for that product. Returns a list of BookingAvailability objects, each containing the OrderItem and its corresponding time slots.'
    )
    public static List<List<BookingAvailability>> getAvailableSlots(List<BookingAvailabilityInput> inputs) {
        List<List<BookingAvailability>> allResults = new List<List<BookingAvailability>>();

        for (BookingAvailabilityInput input : inputs) {
            
            // Query OrderItems to get Product2Ids
            Map<Id, OrderItem> orderItemsMap = new Map<Id, OrderItem>([
                SELECT Id, Product2Id 
                FROM OrderItem 
                WHERE Id IN :input.orderItemIds
            ]);

            // Get unique Product2Ids
            Set<Id> uniqueProductIds = new Set<Id>();
            for (OrderItem oi : orderItemsMap.values()) {
                if (oi.Product2Id != null) {
                    uniqueProductIds.add(oi.Product2Id);
                }
            }
      
            // Get Product Bookable Location if Location is Included
            Map<Id,Id> productToBookableLocationMap =
                getProductBookableLocationMap(uniqueProductIds, input.bookableLocationId);
            
            // Compute per-product slot limit (distribute total evenly)
            Integer numProducts = uniqueProductIds.size();
            Integer perProductLimit = (numProducts > 0) ? maxSlotsTotal / numProducts : 0;
            
            // Compute slots for each unique product, limiting results
            Map<Id, List<TimeSlotResult>> productToSlots = new Map<Id, List<TimeSlotResult>>();
            Map<Id, Boolean> productToMoreSlotsFound = new Map<Id, Boolean>();
            for (Id productId : uniqueProductIds) {
                Id pblId = productToBookableLocationMap.get(productId);
                if (input.bookableLocationId != null && pblId == null) {
                    productToSlots.put(productId, new List<TimeSlotResult>());
                    productToMoreSlotsFound.put(productId, false);
                    continue;
                }
                List<BookingAvailabilityCalculator.DayResult> days = 
                    BookingAvailabilityCalculator.calculateSlots(
                        productId,
                        input.startDate,
                        input.endDate,
                        pblId
                    );

                Integer totalPossible = 0;
                for (BookingAvailabilityCalculator.DayResult day : days) {
                    totalPossible += day.timeSlots.size();
                }
                Boolean moreSlots = totalPossible > perProductLimit;
                productToMoreSlotsFound.put(productId, moreSlots);

                List<TimeSlotResult> thisSlots = new List<TimeSlotResult>();
                Integer slotsAdded = 0;
                for (BookingAvailabilityCalculator.DayResult day : days) {
                    for (BookingAvailabilityCalculator.TimeSlot slot : day.timeSlots) {
                        if (slotsAdded >= perProductLimit) {
                            break; // Stop if per-product limit reached
                        }
                        TimeSlotResult tsr = new TimeSlotResult();
                        tsr.dateValue = day.dateValue;
                        tsr.bookableLocationName = day.bookableLocationName;
                        tsr.productBookableLocationId = day.productBookableLocationId;
                        tsr.startTime = slot.startTime;
                        tsr.endTime = slot.endTime;
                      //tsr.startsAt = slot.startsAt;
                      //tsr.endsAt = slot.endsAt;
                        tsr.bookingSlotsBooked = slot.bookingSlotsBooked;
                        tsr.bookingSlotsAvailable = slot.bookingSlotsAvailable;
                        tsr.bookingSlotsTotal = slot.bookingSlotsTotal;
                        tsr.bookingSlotsFull = slot.bookingSlotsFull;
                        tsr.unlimited = slot.unlimited;
                        tsr.locationTimezone = slot.locationTimezone;
                        thisSlots.add(tsr);
                        slotsAdded++;
                    }
                    if (slotsAdded >= perProductLimit) {
                        break;
                    }
                }
                
                productToSlots.put(productId, thisSlots);
            }

            // Build results per OrderItem
            List<BookingAvailability> thisResult = new List<BookingAvailability>();
            for (OrderItem oi : orderItemsMap.values()) {
                if (oi.Product2Id != null && productToSlots.containsKey(oi.Product2Id)) {
                    BookingAvailability ba = new BookingAvailability();
                    ba.orderItem = oi;
                    ba.timeSlots = productToSlots.get(oi.Product2Id);
                    ba.moreSlotsFound = productToMoreSlotsFound.get(oi.Product2Id);
                    thisResult.add(ba);
                }
            }
            allResults.add(thisResult);
        }

        return allResults;
    }
    
    private static Map<Id,Id> getProductBookableLocationMap(
    Set<Id> productIds,
    Id bookableLocationId
    ) {
        Map<Id,Id> productToPBL = new Map<Id,Id>();
        if (bookableLocationId != null && !productIds.isEmpty()) {
            for (s_c__Product_Bookable_Location__c pbl : [
                SELECT Id, s_c__Product_Id__c
                FROM   s_c__Product_Bookable_Location__c
                WHERE  s_c__Bookable_Location_Id__c = :bookableLocationId
                  AND  s_c__Product_Id__c IN :productIds
            ]) {
                productToPBL.put(pbl.s_c__Product_Id__c, pbl.Id);
            }
        }
        return productToPBL;
    }
}