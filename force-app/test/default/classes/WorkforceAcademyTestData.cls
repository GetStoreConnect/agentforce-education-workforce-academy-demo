@IsTest
public class WorkforceAcademyTestData {
    public static Id storeId;
    public static Id bookableLocationId;
    public static Id productBookableLocationId;
    public static Id productId;
    public static Id productWithoutLocationId;
    public static Id pricebookEntryId;
    public static Id pricebookEntryWithoutLocationId;
    public static Id orderId;
    public static Id orderItemId;
    public static Id contactId;
    public static Date availabilityStartDate;

    public static void load() {
        if (storeId != null) {
            return;
        }

        availabilityStartDate = Date.today().addDays(3);
        Date availabilityEndDate = availabilityStartDate.addDays(2);

        RecordType personRt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Account'
              AND IsPersonType = true
            LIMIT 1
        ];

        Account personAccount = new Account(
            RecordTypeId = personRt.Id,
            LastName = 'Workforce Test',
            PersonEmail = 'tester@example.com'
        );
        insert personAccount;

        contactId = [
            SELECT PersonContactId
            FROM Account
            WHERE Id = :personAccount.Id
        ].PersonContactId;

        s_c__Store__c store = new s_c__Store__c(
            Name = 'Demo Store',
            s_c__Domain__c = 'demo.storeconnect.local'
        );
        insert store;
        storeId = store.Id;

        Product2 primaryProduct = new Product2(
            Name = 'Bookable Product',
            ProductCode = 'BOOK-1001',
            IsActive = true,
            s_c__Slug__c = 'bookable-product',
            s_c__Booking_Duration__c = 60,
            s_c__Booking_Start_Buffer__c = 15,
            s_c__Booking_End_Buffer__c = 15
        );
        insert primaryProduct;
        productId = primaryProduct.Id;

        Product2 secondaryProduct = new Product2(
            Name = 'Unmapped Product',
            ProductCode = 'BOOK-1002',
            IsActive = true,
            s_c__Slug__c = 'unmapped-product',
            s_c__Booking_Duration__c = 30
        );
        insert secondaryProduct;
        productWithoutLocationId = secondaryProduct.Id;

        Id standardPricebookId = Test.getStandardPricebookId();
        update new Pricebook2(Id = standardPricebookId, IsActive = true);

        PricebookEntry primaryEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = productId,
            UnitPrice = 125,
            IsActive = true,
            UseStandardPrice = false
        );
        insert primaryEntry;
        pricebookEntryId = primaryEntry.Id;

        PricebookEntry secondaryEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = productWithoutLocationId,
            UnitPrice = 150,
            IsActive = true,
            UseStandardPrice = false
        );
        insert secondaryEntry;
        pricebookEntryWithoutLocationId = secondaryEntry.Id;

        s_c__Bookable_Location__c location = new s_c__Bookable_Location__c(
            Name = 'Downtown Campus',
            s_c__Timezone__c = 'GMT',
            s_c__store_id__c = storeId,
            s_c__Active__c = TRUE
        );
        insert location;
        bookableLocationId = location.Id;

        s_c__Product_Bookable_Location__c pbl = new s_c__Product_Bookable_Location__c(
            s_c__Product_Id__c = productId,
            s_c__Bookable_Location_Id__c = bookableLocationId,
            s_c__Max_Bookings__c = 5
        );
        insert pbl;
        productBookableLocationId = pbl.Id;

        List<String> dayNames = new List<String>{
            'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'
        };
        Integer dayIndex = Math.mod(availabilityStartDate.toStartOfWeek().daysBetween(availabilityStartDate), 7);
        String dayLabel = dayNames[dayIndex];

        insert new s_c__Availability__c(
            Name = 'Morning Window',
            s_c__Product_Bookable_Location_Id__c = productBookableLocationId,
            s_c__Unavailable__c = false,
            s_c__Start_Date__c = availabilityStartDate,
            s_c__End_Date__c = availabilityEndDate,
            s_c__Start_Time__c = Time.newInstance(8, 0, 0, 0),
            s_c__End_Time__c = Time.newInstance(10, 0, 0, 0),
            s_c__Days_Of_Week__c = dayLabel
        );

        insert new s_c__Availability__c(
            Name = 'Mid Morning Blackout',
            s_c__Product_Bookable_Location_Id__c = productBookableLocationId,
            s_c__Unavailable__c = true,
            s_c__Start_Date__c = availabilityStartDate,
            s_c__End_Date__c = availabilityStartDate,
            s_c__Start_Time__c = Time.newInstance(10, 0, 0, 0),
            s_c__End_Time__c = Time.newInstance(12, 0, 0, 0),
            s_c__Days_Of_Week__c = dayLabel
        );

        insert new s_c__Bookable_Event__c(
            Name = 'Afternoon Workshop',
            s_c__Product_Bookable_Location_Id__c = productBookableLocationId,
            s_c__Start_Date__c = availabilityStartDate,
            s_c__End_Date__c = availabilityStartDate,
            s_c__Start_Time__c = Time.newInstance(13, 0, 0, 0),
            s_c__End_Time__c = Time.newInstance(15, 0, 0, 0),
            s_c__Created_From_Availability__c = false
        );

        Order primaryOrder = new Order(
            AccountId = personAccount.Id,
            BillToContactId = contactId,
            EffectiveDate = availabilityStartDate,
            Status = 'Draft',
            Pricebook2Id = standardPricebookId,
            s_c__Store_Id__c = storeId,
            s_c__Contact_Id__c = contactId
        );
        insert primaryOrder;
        orderId = primaryOrder.Id;

        Order secondaryOrder = new Order(
            AccountId = personAccount.Id,
            BillToContactId = contactId,
            EffectiveDate = availabilityStartDate.addDays(1),
            Status = 'Draft',
            Pricebook2Id = standardPricebookId,
            s_c__Store_Id__c = storeId,
            s_c__Contact_Id__c = contactId
        );
        insert secondaryOrder;

        OrderItem primaryItem = new OrderItem(
            OrderId = orderId,
            PricebookEntryId = pricebookEntryId,
            Product2Id = productId,
            Quantity = 1,
            UnitPrice = 125
        );
        insert primaryItem;
        orderItemId = primaryItem.Id;
    }
}
