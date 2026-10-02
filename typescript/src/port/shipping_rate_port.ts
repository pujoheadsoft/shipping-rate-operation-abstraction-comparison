import type { Shipment } from "../domain/shipment.ts";
import type { ShippingRates } from "../domain/shipping_rates.ts";

export interface ShippingRatePort {
  fetchShippingRates(shipment: Shipment): ShippingRates;
}
