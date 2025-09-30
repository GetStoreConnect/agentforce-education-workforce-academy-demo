/*****************************************************************************************
*  StoreConnect BOOKING‑AVAILABILITY CALCULATOR                                          *
*                                                                                        *
*  Public entry points:                                                                  *
*     • calculateSlots(...)      → List<DayResult>                                       *
*     • calculateHighlights(...) → Set<Date>                                             *
* Notes:                                                                                 *
* There is no 'purchasable form store' logic on this class, productId should be         *
* purchasable from the store.                                                           *
*****************************************************************************************/
public with sharing class BookingAvailabilityCalculator {

    /** Detailed slot view (calendar grid). */
    public static List<DayResult> calculateSlots(
        Id   productId,
        Date startDate,
        Date endDate,
        Id   productBookableLocationId
    ) {
        return runAvailability(
            productId,
            startDate,
            endDate,
            productBookableLocationId,
            false
        ).dayResults;
    }

    /** Dates that have ≥ 1 slot (for date‑picker “dots”). */
    public static Set<Date> calculateHighlights(
        Id   productId,
        Date startDate,
        Date endDate,
        Id   productBookableLocationId
    ) {
        return runAvailability(
            productId,
            startDate,
            endDate,
            productBookableLocationId,
            true
        ).highlightDates;
    }

    /* ====================================================================== *
     *  Availability WORKFLOW                                                 *
     * ====================================================================== */

    private class AvailabilityResult {
        public List<DayResult> dayResults = new List<DayResult>();
        public Set<Date>       highlightDates = new Set<Date>();
    }

    private static AvailabilityResult runAvailability(
        Id   productId,
        Date startDate,
        Date endDate,
        Id   pblId,
        Boolean highlightsOnly
    ) {
        AvailabilityResult result = new AvailabilityResult();

        /* ------------------------ 0. Sanity Check ------------------------- */
        if (productId == null || endDate == null) {
            return result;            // both lists remain empty
        }
        if (startDate == null) startDate = Date.today();
        if (startDate > endDate) {
            Date tmp = startDate;     // swap if caller inverted them
            startDate = endDate;
            endDate   = tmp;
        }

        /* ------------------------ 1. Get data ---------------------------- */

        Product2 product = [
            SELECT s_c__Booking_Duration__c,
                   s_c__Booking_Start_Buffer__c,
                   s_c__Booking_End_Buffer__c
              FROM Product2
             WHERE Id = :productId
             LIMIT 1
        ];
		List<s_c__Product_Bookable_Location__c> pbls = new List<s_c__Product_Bookable_Location__c>();
        if(String.IsBlank(pblId) || pblId == null){
            pbls = [
            SELECT Id,
                   Name,
                   s_c__Max_Bookings__c,
                   s_c__Bookable_Location_Id__c,
                   s_c__Bookable_Location_Id__r.s_c__Timezone__c,
				   Location_Name__c
              FROM s_c__Product_Bookable_Location__c
             WHERE s_c__Product_Id__c = :productId
        ];
        } else {
            pbls = [
            SELECT Id,
                   Name,
                   s_c__Max_Bookings__c,
                   s_c__Bookable_Location_Id__c,
                   s_c__Bookable_Location_Id__r.s_c__Timezone__c,
				   Location_Name__c
              FROM s_c__Product_Bookable_Location__c
             WHERE s_c__Product_Id__c = :productId
                   AND Id = :pblId 
        	];
        }

        if (pbls.isEmpty()) {
            return result;
        }

        /* 1a. Recurring Availability + Unavailability */
        Map<Id, List<s_c__Availability__c>> availByPbl  = new Map<Id,List<s_c__Availability__c>>();
        Map<Id, List<s_c__Availability__c>> unavailByPbl = new Map<Id,List<s_c__Availability__c>>();

        for (s_c__Availability__c av :
             [ SELECT Id,
                      s_c__Product_Bookable_Location_Id__c,
                      s_c__Unavailable__c,
                      s_c__Start_Date__c, s_c__End_Date__c,
                      s_c__Start_Time__c, s_c__End_Time__c,
              		  s_c__Days_Of_Week__c
                 FROM s_c__Availability__c
                WHERE s_c__Product_Bookable_Location_Id__c IN :pbls
                      AND s_c__End_Date__c   >= :startDate
                      AND s_c__Start_Date__c <= :endDate ])
        {
            Map<Id,List<s_c__Availability__c>> bucket =
                av.s_c__Unavailable__c ? unavailByPbl : availByPbl;

            if (!bucket.containsKey(av.s_c__Product_Bookable_Location_Id__c)) {
                bucket.put(av.s_c__Product_Bookable_Location_Id__c,
                           new List<s_c__Availability__c>());
            }
            bucket.get(av.s_c__Product_Bookable_Location_Id__c).add(av);
        }

        /* 1b. One-off Bookable Events within window */
        Map<Id, List<s_c__Bookable_Event__c>> eventsByPbl = new Map<Id, List<s_c__Bookable_Event__c>>();
        
        for (s_c__Bookable_Event__c ev : [
            SELECT Id,
                   s_c__Product_Bookable_Location_Id__c,
                   s_c__Start_Date__c, 
                   s_c__End_Date__c,
                   s_c__Start_Time__c, 
                   s_c__End_Time__c,
                   s_c__Created_From_Availability__c
              FROM s_c__Bookable_Event__c
             WHERE s_c__Product_Bookable_Location_Id__c IN :pbls
               AND s_c__Start_Date__c >= :startDate
               AND s_c__End_Date__c <= :endDate
               AND s_c__Created_From_Availability__c = false // EVs where this is true should be handled by s_c__Availability__c
        ]) {
            Id pblIdOF = ev.s_c__Product_Bookable_Location_Id__c;
            if (!eventsByPbl.containsKey(pblIdOF)) {
                eventsByPbl.put(pblIdOF, new List<s_c__Bookable_Event__c>());
            }
            eventsByPbl.get(pblIdOF).add(ev);
        }

        /* 1c. Booking counts (aggregated) */
        Map<Id, Integer> bookingCountByEvent = new Map<Id,Integer>();
        if (!eventsByPbl.isEmpty()) {
            AggregateResult[] counts = [
                SELECT s_c__Bookable_Event_Id__c beId, COUNT(Id) cnt
                  FROM s_c__Booking__c
                 WHERE s_c__Bookable_Event_Id__c IN :eventsByPbl.keySet()
                 GROUP BY s_c__Bookable_Event_Id__c
            ];
            for (AggregateResult ar : counts) {
                bookingCountByEvent.put((Id)ar.get('beId'),
                                        (Integer)ar.get('cnt'));
            }
        }

        /* ------------------- 2. Generate slots / highlights -------------- */

        for (s_c__Product_Bookable_Location__c pbl : pbls) {
            PblContext ctx = new PblContext(
                pbl,
                product,
                availByPbl.get(pbl.Id),
                unavailByPbl.get(pbl.Id),
                eventsByPbl.get(pbl.Id),
                bookingCountByEvent
            );

            for (Date d = startDate; d <= endDate; d = d.addDays(1)) {
                DayResult day = ctx.buildDay(d);
                if (day == null) continue;

                if (highlightsOnly) {
                    if (!day.timeSlots.isEmpty()) {
                        result.highlightDates.add(day.dateValue);
                    }
                } else {
                    result.dayResults.add(day);
                }
            }
        }

        /* 2b. For detailed grid – sort and add closest if absolutely empty */
        if (!highlightsOnly) {
            result.dayResults.sort();   // Comparable implementation

            Boolean anySlot = false;
            for (DayResult dr : result.dayResults) {
                if (!dr.timeSlots.isEmpty()) { anySlot = true; break; }
            }
            if (!anySlot) {
                // The "closest before / after" logic can be implemented here if needed
            }
        }

        return result;
    }
    
    /* ------------------------------------------------------------------ *
     *  TimeRange list helpers *
     * ------------------------------------------------------------------ */
    private static List<TimeRange> mergeRanges(List<TimeRange> src) {
        if (src.isEmpty()) return src;
    
        src.sort();
        List<TimeRange> out = new List<TimeRange>{ src[0] };
    
        for (Integer i = 1; i < src.size(); i++) {
            TimeRange last = out[out.size() - 1];
            TimeRange curr = src[i];
    
            if ( last.overlaps(curr)
              || last.endValue.getTime() == curr.beginValue.getTime() )
            {
                out[out.size() - 1] = last.unionWith(curr);
            } else {
                out.add(curr);
            }
        }
        return out;
    }

    private static List<TimeRange> subtractRangeList(
            List<TimeRange> src, TimeRange removeMe) {

        List<TimeRange> next = new List<TimeRange>();
        for (TimeRange r : src) {
            next.addAll(r.subtract(removeMe));
        }
        return next;
    }

    /* ====================================================================== *
     *  PER‑PBL CONTEXT                                                       *
     * ====================================================================== */

    private class PblContext {
        /* -------- injected references ---------- */
        private final s_c__Product_Bookable_Location__c pbl;
        private final Product2 product;
        private final List<s_c__Availability__c> avail;
        private final List<s_c__Availability__c> unavail;
        private final List<s_c__Bookable_Event__c> events;
        private final Map<Id,Integer> bookingCntByEvent;
    
        /* -------- derived / constants ---------- */
        private final Integer durationMins;
        private final Integer startBufMins;
        private final Integer endBufMins;
        private final Integer maxBookings;
        private final Integer MAX_VALUE = 2147483647;
        private final TimeZone locationTz;
        
        private DateTime localDateTimeToGmt(Date d, Time t) {
            Integer offset = locationTz.getOffset(d);
            Integer offsetSeconds = offset / 1000;
            DateTime dtGmt = DateTime.newInstanceGmt(d, t).addSeconds(-offsetSeconds);
            return dtGmt;
        }
    
        private DateTime dateTimeFromDateAndTime(Date d, Time t) {
            return localDateTimeToGmt(d, t);
        }
    
        private TimeRange rangeFromAvailability(s_c__Availability__c av, Date dateValue) {
            DateTime startDt = localDateTimeToGmt(dateValue, av.s_c__Start_Time__c);
            DateTime endDt = localDateTimeToGmt(dateValue, av.s_c__End_Time__c);
            return new TimeRange(startDt, endDt);
    	}

		PblContext(
            s_c__Product_Bookable_Location__c pbl,
            Product2 product,
            List<s_c__Availability__c> avail,
            List<s_c__Availability__c> unavail,
            List<s_c__Bookable_Event__c> events,
            Map<Id,Integer> bookingCntByEvent
        ) {
            this.pbl               = pbl;
            this.product           = product;
            this.avail             = (avail   == null) ? new List<s_c__Availability__c>()   : avail;
            this.unavail           = (unavail == null) ? new List<s_c__Availability__c>()   : unavail;
            this.events            = (events  == null) ? new List<s_c__Bookable_Event__c>() : events;
            this.bookingCntByEvent = bookingCntByEvent == null ? new Map<Id,Integer>()      : bookingCntByEvent;
    
            durationMins  = (product.s_c__Booking_Duration__c     == null) ? 0 :
                             Integer.valueOf(product.s_c__Booking_Duration__c);
            startBufMins  = (product.s_c__Booking_Start_Buffer__c == null) ? 0 :
                             Integer.valueOf(product.s_c__Booking_Start_Buffer__c);
            endBufMins    = (product.s_c__Booking_End_Buffer__c   == null) ? 0 :
                             Integer.valueOf(product.s_c__Booking_End_Buffer__c);
            maxBookings   = (pbl.s_c__Max_Bookings__c == null) ? MAX_VALUE :
                             Integer.valueOf(pbl.s_c__Max_Bookings__c);
            locationTz    = TimeZone.getTimeZone(pbl.s_c__Bookable_Location_Id__r.s_c__Timezone__c);
        }

        /**
         * Build one DayResult for a calendar date in the **current user’s** TZ.
         * Returns null if the date is before today (slots would all be expired).
         */
		DayResult buildDay(Date dateValue) {
            
        if (dateValue < Date.today()) {
            return null;
        }

        /* 1. Build merged availability ranges for the day */
        List<TimeRange> availRanges = new List<TimeRange>();
        for (s_c__Availability__c av : avail) {
            if (dateOccurs(av, dateValue)) {
                TimeRange range = rangeFromAvailability(av, dateValue);
                availRanges.add(range);
            }
        }
        List<TimeRange> mergedAvail = mergeRanges(availRanges);

        /* 2. Remove unavailable windows */
        for (s_c__Availability__c un : unavail) {
            if (dateOccurs(un, dateValue)) {
                TimeRange unRange = rangeFromAvailability(un, dateValue);
                mergedAvail = subtractRangeList(mergedAvail, unRange);
            }
        }

        /* 3. Generate recurring-availability slots */
        List<TimeSlot> slots = new List<TimeSlot>();
        for (TimeRange r : mergedAvail) {
            DateTime nextStart = r.beginValue.addMinutes(startBufMins);
            DateTime nextEnd = nextStart.addMinutes(durationMins);
            while (nextEnd.getTime() <= r.endValue.getTime()) {
                TimeSlot slot = buildSlot(dateValue, nextStart, nextEnd);
                slots.add(slot);
                nextStart = nextEnd.addMinutes(endBufMins + startBufMins);
                nextEnd = nextStart.addMinutes(durationMins);
            }
        }

        /*  4. Inject one-off Bookable Events (stand-alone). */
        for (s_c__Bookable_Event__c ev : events) {
            if (ev.s_c__Start_Date__c == dateValue) {
                DateTime s = dateTimeFromDateAndTime(ev.s_c__Start_Date__c, ev.s_c__Start_Time__c);
                DateTime e = dateTimeFromDateAndTime(ev.s_c__End_Date__c, ev.s_c__End_Time__c);
                TimeSlot slot = buildSlot(dateValue, s, e);
                slots.add(slot);
            }
        }

        /* 5. Prune slots that already started */
        DateTime now = System.now();
        List<TimeSlot> validSlots = new List<TimeSlot>();
        for (TimeSlot ts : slots) {
            if (ts.startsAt.getTime() >= now.getTime()) {
                validSlots.add(ts);
            } else {
                System.debug('Pruned slot (past): ' + ts.startsAt + ' to ' + ts.endsAt);
            }
        }
        slots = dedupeSlots(validSlots);

        /* 6. Decorate with booking counts */
        for (TimeSlot s : slots) {
            Integer booked = 0;
            for (s_c__Bookable_Event__c ev : events) {
                if (s.matchesEvent(ev)) {
                    if (bookingCntByEvent.containsKey(ev.Id)) {
                        booked += bookingCntByEvent.get(ev.Id);
                    }
                }
            }
            Integer availSpots = Math.max(0, maxBookings - booked);
            s.bookingSlotsBooked = booked;
            s.bookingSlotsAvailable = availSpots;
            s.bookingSlotsTotal = maxBookings;
            s.bookingSlotsFull = (availSpots == 0);
            s.unlimited = (maxBookings == MAX_VALUE);
        }
            
        DayResult day = new DayResult(dateValue, pbl.Location_Name__c , pbl.Id, slots);
        return day;
    }

        /* ---------- helper functions in PblContext ---------------------- */
        
        private Boolean dateOccurs(s_c__Availability__c av, Date d) {
            // Check if date is within the availability's date range
            if (d < av.s_c__Start_Date__c || d > av.s_c__End_Date__c) {
                return false;
            }
        
            // If s_c__Days_Of_Week__c is blank, apply to all days (backward compatibility)
            if (String.isBlank(av.s_c__Days_Of_Week__c)) {
                return true;
            }
        
            // Calculate day of the week (0=Sunday, 1=Monday, ..., 6=Saturday)
            Date startOfWeek = d.toStartOfWeek();
            Integer dayOfWeek = Math.mod(startOfWeek.daysBetween(d), 7);
            String[] daysOfWeek = new String[]{'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'};
            
            // Ensure dayOfWeek is valid
            if (dayOfWeek < 0 || dayOfWeek >= daysOfWeek.size()) {
                return false; // Prevent index out-of-bounds
            }
        
            String targetDay = daysOfWeek[dayOfWeek];
        
            // Check if the target day is in the multi-select picklist
            String[] allowedDays = av.s_c__Days_Of_Week__c.split(';');
            Boolean isAllowedDay = false;
            for (String allowedDay : allowedDays) {
                if (allowedDay.equalsIgnoreCase(targetDay)) {
                    isAllowedDay = true;
                    break;
                }
            }
        
            return isAllowedDay;
        }
        
		private TimeSlot buildSlot(Date d, DateTime s, DateTime e) {
            Integer offset = locationTz.getOffset(s.dateGmt());
            Integer offsetSeconds = offset / 1000;
            DateTime localS = s.addSeconds(offsetSeconds);
            DateTime localE = e.addSeconds(offsetSeconds);

            Time startT = Time.newInstance(
                localS.hourGmt(),
                localS.minuteGmt(),
                localS.secondGmt(),
                localS.millisecondGmt()
            );
            Time endT = Time.newInstance(
                localE.hourGmt(),
                localE.minuteGmt(),
                localE.secondGmt(),
                localE.millisecondGmt()
            );

            return new TimeSlot(d, startT, endT, s, e, locationTz.getID());
        }
        
        private List<TimeSlot> dedupeSlots(List<TimeSlot> source) {
            Map<String, TimeSlot> index = new Map<String, TimeSlot>();
            for (TimeSlot s : source) {
                String key = String.valueOf(s.startsAt.getTime()) +
                             '-' + String.valueOf(s.endsAt.getTime());
                index.put(key, s);
            }
            List<TimeSlot> deduped = new List<TimeSlot>(index.values());
            deduped.sort();
            return deduped;
        }
    }

    /* ====================================================================== *
     *  SUPPORTING VALUE CLASSES                                              *
     * ====================================================================== */

    /** Inclusive‑exclusive DateTime range. */
    public class TimeRange implements Comparable {
        public DateTime beginValue { get; private set; }
        public DateTime endValue   { get; private set; }
    
        public TimeRange(DateTime b, DateTime e) {
            beginValue = b;
            endValue   = e;
        }
    
        /* ---------- instance helpers ---------- */
        public Boolean overlaps(TimeRange other) {
            return !( other.endValue.getTime()   <= beginValue.getTime()
                   || other.beginValue.getTime() >= endValue.getTime() );
        }
    
        /** Return the union of two **overlapping or touching** ranges. */
        public TimeRange unionWith(TimeRange other) {
            DateTime b = (beginValue.getTime() < other.beginValue.getTime())
                         ? beginValue : other.beginValue;
            DateTime e = (endValue.getTime()   > other.endValue.getTime())
                         ? endValue   : other.endValue;
            return new TimeRange(b, e);
        }
    
        /** Subtract `other` from `this` (0–2 residual ranges). */
        public List<TimeRange> subtract(TimeRange other) {
            List<TimeRange> out = new List<TimeRange>();
            if (!overlaps(other)) { out.add(this); return out; }
    
            if (other.beginValue.getTime() > beginValue.getTime()) {
                out.add(new TimeRange(beginValue, other.beginValue));
            }
            if (other.endValue.getTime() < endValue.getTime()) {
                out.add(new TimeRange(other.endValue, endValue));
            }
            return out;
        }
    
        /* ---------- Comparable so we can List.sort() ---------- */
        public Integer compareTo(Object otherObj) {
            TimeRange other = (TimeRange) otherObj;
            if (beginValue == other.beginValue) return 0;
            return (beginValue.getTime() < other.beginValue.getTime()) ? -1 : 1;
        }
    }

    /** Individual slot record returned to UI. */
	public class TimeSlot implements Comparable {
        public Date dateValue;
        public Time startTime;
        public Time endTime;
        public DateTime startsAt;
        public DateTime endsAt;
        public String locationTimezone;
        /* Decorated later */
		public Integer bookingSlotsBooked;
        public Integer bookingSlotsAvailable;
        public Integer bookingSlotsTotal;
        public Boolean bookingSlotsFull;
        public Boolean unlimited;

        public TimeSlot(
            Date d, Time st, Time et, DateTime sAt, DateTime eAt, String tz
        ) {
            dateValue      = d;
            startTime = st;
            endTime   = et;
            startsAt  = sAt;
            endsAt    = eAt;
            locationTimezone = tz;  // New
        }

        public Boolean matchesEvent(s_c__Bookable_Event__c ev) {
            return ev.s_c__Start_Date__c == dateValue &&
                   ev.s_c__Start_Time__c == startTime &&
                   ev.s_c__End_Time__c   == endTime;
        }
        public Integer compareTo(Object o) {
            TimeSlot other = (TimeSlot)o;
            if (startsAt == other.startsAt) return 0;
            return (startsAt.getTime() < other.startsAt.getTime()) ? -1 : 1;
        }
    }

    /** Day‑level grouping wrapper. */
    public class DayResult implements Comparable {
        public Date    dateValue;
        public String  bookableLocationName;
        public Id      productBookableLocationId;
        public List<TimeSlot> timeSlots;

        public DayResult(
            Date d,
            String locationName,
            Id pblId,
            List<TimeSlot> slots
        ) {
            dateValue                    = d;
            bookableLocationName    = locationName;
            productBookableLocationId = pblId;
            timeSlots               = slots;
            timeSlots.sort();
        }

        public Integer compareTo(Object o) {
            DayResult other = (DayResult)o;
            if (dateValue != other.dateValue) {
                return (dateValue.daysBetween(other.dateValue) > 0) ? -1 : 1;
            }
            return bookableLocationName.toLowerCase()
                       .compareTo(other.bookableLocationName.toLowerCase());
        }
    }
}