import type { Shipment } from "../domain/shipment.ts";
import type { ShippingRates } from "../domain/shipping_rates.ts";
import { error, type Result } from "../data/result.ts";
import type { ShippingRatePort } from "../port/shipping_rate_port.ts";
import { type GetShippingRatesError, GetShippingRatesFailed } from "./get_shipping_rates_error.ts";

type GetShippingRatesResult = Result<GetShippingRatesError, ShippingRates>;

export const getShippingRates = (port: ShippingRatePort) => {
  return async (shipment: Shipment): Promise<GetShippingRatesResult> => {
    const result = await port.fetchShippingRates(shipment);
    return result.type === "ok" ? result : error(GetShippingRatesFailed);
  };
};
