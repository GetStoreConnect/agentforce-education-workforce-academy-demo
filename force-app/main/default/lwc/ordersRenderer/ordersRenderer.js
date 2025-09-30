import { LightningElement, api, track } from 'lwc';

export default class OrdersRenderer extends LightningElement {
  @api value;
  @track activeSections = [];

  get computedValue() {
    if (!this.value) return [];
    return this.value.map(order => ({
      ...order,
      summaryLabel: `Order ${order.orderNumber} - ${order.orderDate} - Status: ${order.status}`
    }));
  }

  get isMultiple() {
    return this.computedValue && this.computedValue.length > 1;
  }

  get isSingle() {
    return this.computedValue && this.computedValue.length === 1;
  }

  get hasOrders() {
    return this.computedValue && this.computedValue.length > 0;
  }

  get singleOrder() {
    return this.isSingle ? this.computedValue[0] : null;
  }

  connectedCallback() {
    if (this.isMultiple) {
      this.activeSections = []; // Start collapsed for lists
    }
  }

  handleViewOrder(event) {
    window.open(event.target.dataset.url, '_blank');
  }
}