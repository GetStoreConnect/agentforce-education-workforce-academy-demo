# StoreConnect Workforce Academy Agentforce Package

This repository contains the metadata for the StoreConnect Workforce Academy second-generation (2GP) managed package that powers the Workforce Academy Agentforce demo. It bundles the flows, Apex services and Agentforce (GenAI) assets required to deliver conversational commerce, career exploration, and booking experiences backed by StoreConnect.

## Highlights
- 2GP-ready Salesforce DX project aligned to StoreConnect Workforce Academy storytelling.
- End-to-end Agentforce implementation, including topic plugins, GenAI functions, and renderer LWCs for rich order and booking responses.
- Opinionated flows and Apex classes for order creation, catalog discovery, booking management, and contact lifecycle automation.
- Permission sets and custom metadata that simplify demo setup.

## Managed Package Dependencies
Install the required managed package versions before deploying or packaging this metadata. They are already declared in `sfdx-project.json`.

| Package | Version | Subscriber Package Version Id |
| --- | --- | --- |
| StoreConnect eCommerce | v20.6 | `04tMn000002kiZZIAY` |
| StoreConnect Agentforce Package | v1.7 | `04tMn000002S8vxIAC` |

Example installation commands for a target org:

```bash
sf package install --package 04tMn000002kiZZIAY --wait 20 --no-prompt
sf package install --package 04tMn000002S8vxIAC --wait 20 --no-prompt
```

### Org Prerequisites
- Person Accounts should be enabled. The included scratch org definition (`config/project-scratch-def.json`) turns this on automatically; enable it in target orgs before deploying the metadata to match the intended configuration.

## Agentforce Assets
### Topic Plugins
| Plugin | Purpose | Functions Invoked |
| --- | --- | --- |
| Account Management | Account creation, profile updates, and password reset flows. | `GetContactInformationFromId`, `CreateOrUpdateContact`, `SetVariables` |
| Booking Scheduling | Find and confirm class bookings tied to draft orders. | `SaveTimeslotBooking`, `GetBookableLocations`, `GetOrderAndItems`, `GetBookingAvailabilityTimeSlotsforOrderItems` |
| Career Exploration | Surface available Workforce Academy careers and guided selection. | `GetCareer`, `GetCareersList`, `SetVariables` |
| Certification Guidance | Explore certification pathways and drill into specific options. | `GetCertificationsForCareerByCareerId`, `GetCertification`, `SetVariables` |
| General Inquiries | Answer general store questions and discover purchasable items. | `GetStoreFromDomainName`, `SetVariables`, `SearchGeneralProducts` |
| Module Selection | Review required modules for a certification and prep enrollment. | `GetRequiredModulesForCertification`, `GetPurchasableProducts`, `SetVariables` |
| Order History | Retrieve and inspect a customer's past purchases. | `SetVariables`, `OrderHistory`, `GetOrderIdFromOrderNumber` |
| Order Management | Draft, amend, and finalize orders for modules or products. | `CreateNewOrder`, `AddOrRemoveOrderItemsFromOrder`, `SetVariables`, `GetPurchasableProducts`, `SearchGeneralProducts`, `GetOrderAndItemsLWC`, `GetOrderIdFromOrderNumber`, `CreateNewGuestOrder` |

### GenAI Functions
- **Order lifecycle**: `CreateNewOrder`, `CreateNewGuestOrder`, `GetOrderAndItems`, `GetOrderAndItemsLWC`, `GetOrderIdFromOrderNumber`, `AddOrRemoveOrderItemsFromOrder`, and `CompleteOrder` expose flows and Apex invocations that create, hydrate, amend, and finalize draft orders with payment links.
- **Order intelligence**: `OrderHistory` returns historical purchases for rendering alongside current cart context.
- **Booking management**: `GetBookingAvailabilityTimeSlotsforOrderItems`, `GetBookingTimeSlots`, `SaveTimeslotBooking`, and `GetBookableLocations` coordinate bookable products, surface available slots, and persist confirmed selections.
- **Account & identity**: `GetContactInformationFromId` and `CreateOrUpdateContact` keep contact records in sync for authenticated and guest flows, including password reset handling.
- **Career & certification discovery**: `GetCareersList`, `GetCareer`, `GetCertificationsForCareerByCareerId`, `GetCertification`, and `GetRequiredModulesForCertification` guide learners from career choice to module roadmap.
- **Catalog discovery**: `GetPurchasableProducts` and `SearchGeneralProducts` validate availability and surface products prior to adding them to an order.
- **Store context**: `SetVariables` and `GetStoreFromDomainName` ensure the Agentforce session maintains the correct StoreConnect context (store, contact, localization).
- **Utility & legacy**: Legacy actions (`AF_UAIS006_Get_Booking_Product_Time_Slots`, `AF_UAIS007_Get_Contact_Information_from_External_Id`, `AF_UAIS009_Confirm_Product_Purchasability`, `AF_UAIS010_Get_Bookable_Location`, `AF_UAIS011_Get_StoreId_from_domain_name`) remain for backward compatibility with earlier Agentforce prompts.

Function metadata lives under `force-app/main/default/genAiFunctions/<FunctionName>/` with JSON schemas for structured input/output and detailed execution guardrails.

## Additional Metadata
- **Flows**: Twenty-seven flows that back each Agentforce function, including `AF_UAIS00x` sub-flows, booking orchestration, and the `RTF_*` fulfillment automations for payments and bookings.
- **Apex services**: `AF_IM_GetOrder`, `AF_IM_GetOrders`, `BA_IM_GetOrderItemTimeSlots`, and the `BookingAvailability*` utilities expose invocable methods for rendering order data and calculating availability.
- **Lightning Web Components**: `ordersRenderer` and `orderRenderer` render single or multiple orders within Agentforce responses, formatting URLs and booking context. These were proof of concept and not currently implemented as part of the demo.
- **Permission sets**: Purpose-built demo roles such as `StoreConnect_Agentforce_Permissions`, `Career_Messaging_Support_Team`, and `Sync_User_Agent_Permissions` accelerate org setup.
- **Manifest**: `manifest/package.xml` surfaces the primary metadata classes to include when creating a package version.

## Working With the Project
1. Authorize a Dev Hub (`sf org login web --set-default-dev-hub`) and, optionally, a scratch org for validation.
2. Install the managed dependencies as shown above.
3. Deploy the source (`sf project deploy start --source-dir force-app`).
4. Assign the relevant permission sets to your test users.
5. Configure Agentforce topics to reference the included plugins and verify conversations via the Workforce Academy storefront.

## Support & Contributions
This project is maintained by StoreConnect for the Workforce Academy demo. Community contributions are welcome via issues. For product assistance, contact [support@getstoreconnect.com](mailto:support@getstoreconnect.com) or visit [support.getstoreconnect.com](https://support.getstoreconnect.com/).
