import { LightningElement, api } from 'lwc';

export default class OrderRenderer extends LightningElement {
    orderData;

  _value;
  @api
  get value() {
    return this._value;
  }
  set value(value) {
    this._value = value;
  }

  connectedCallback() {
    if (this.value) {
        this.orderData = this.value;
        }
    }

}