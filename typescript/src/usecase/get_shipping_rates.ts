import type { Shipment } from "../domain/shipment.ts";
import type { ShippingRates } from "../domain/shipping_rates.ts";
import type { ShippingRatePort } from "../port/shipping_rate_port.ts";

export function getShippingRates(
  _shippingRatePort: ShippingRatePort,
  _shipment: Shipment,
): ShippingRates {
  throw new Error("Not implemented");
}
