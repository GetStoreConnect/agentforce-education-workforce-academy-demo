# StoreConnect Workforce Academy Agentforce Package

This repository contains the metadata for the StoreConnect Workforce Academy second-generation (2GP) managed package that powers the StoreConnect Workforce Academy demo available at [agentforce-edu.storeconnectdemo.com](https://agentforce-edu.storeconnectdemo.com/). It bundles the flows, Apex services and Agentforce (GenAI) assets required to deliver conversational commerce, career exploration, and booking experiences backed by StoreConnect.

Currently this project uses the Order record to create the checkout cart and has other limitations. It is a proof of concept only and should only be used as a base to develop out your own StoreConnect powered Agentforce chat agent.

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

## Salesforce and Store Setup for Agent
| Step | Action | Notes|
| --- | --- | --- |
| 1. | Create your Agent | Create your Agentforce Agent, you can see the setup steps [here](https://www.salesforce.com/en-us/wp-content/uploads/sites/4/Agentforce.pdf) |
| 2. | Enable Omni-Channel | Navigate to Setup > enter Omni Channel in the Quick Find box > click Omni Channel Settings. Click the Enable Omni-Channel checkbox > click Save.  |
| 3. | Omni-Flow Setup | The packaged flow `AF_Omni_Channel_Messaging_Routing_Agentforce` will need to be updated with your local orgs references. |
| 4. | Add a Messaging Channel | Search Messaging Settings in setup. Create a new Messaging Channel for Web. Configure with Omni-Channel Routing to the flow and fallback queue. | 
| 5. | Configure Parameters| Add any parameters and parameter mappings here that you want to pass from the StoreConnect site to the agent (eg storeId and customerId) |
| 6. | Service Deployment Creation | Go to Embedded Service Deployment, create new deployment for web, det you name and domain the chat will be hosted and messaging channel.  |
| 7. | Service Deployment Config | Enable Pre-Chat fields, this will allow the Agent start of session contex (eg the current Store and Customer and any other values you want). Configure other settings as desired. |
| 8. | Publish and Activate | Before adding the code to the StoreConnect site, ensure the Agent is active with correct permissions, Messaging Channel is activated, Omni-Flow is active, Embedded Service Deployment is bpulished and site domain is added to the correct sf site as a Trusted Domains for Inline Frames |
| 9. | Install your Embed Code | For a global chat, add a content block to you store under Content --> Global Content --> Body Content, create a new content block and add the code (example below) |

### Sample Embed Code
```liquid

<script type="text/javascript">

function initEmbeddedMessaging() {
try {
embeddedservice_bootstrap.settings.language = 'en_US';

embeddedservice_bootstrap.init(
'some salesforce org id',
'some embedded service name', 
'https://some-org-id.develop.my.site.com/some-site-url',
{
scrt2URL: 'https://some-cs-url.develop.my.salesforce-scrt.com'
}
);
} catch (err) {
console.error('Error loading Embedded Messaging: ', err);
}
}
</script>

{% if current_customer %} 
<script type="text/javascript">
window.addEventListener("onEmbeddedMessagingReady", function() {
embeddedservice_bootstrap.prechatAPI.setHiddenPrechatFields({
scId: "{{ current_customer.id }}",
storeId: "{{ current_store.id }}"
});
});
</script>
{% else %}
<script type="text/javascript">
window.addEventListener("onEmbeddedMessagingReady", function() {
embeddedservice_bootstrap.prechatAPI.setHiddenPrechatFields({
storeId: "{{ current_store.id }}"
});
});
</script>
{% endif %}

<script type='text/javascript' src='https://some-org.develop.my.site.com/SomeDomain/assets/js/bootstrap.min.js' onload='initEmbeddedMessaging()'></script>

```

## Support & Contributions
This is an open source repository and no direct Agentforce support is provided by StoreConnect beyond direct help on StoreConnect specific functions. For assistance with Agentforce more generally, please contact one of our StoreConnect partners.

This project is maintained by StoreConnect for the Workforce Academy demo. Community contributions are welcome via issues. For product assistance, contact [support@getstoreconnect.com](mailto:support@getstoreconnect.com) or visit [support.getstoreconnect.com](https://support.getstoreconnect.com/).
