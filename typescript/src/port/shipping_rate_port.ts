import type { Result } from "../data/result.ts";
import type { Shipment } from "../domain/shipment.ts";
import type { ShippingRates } from "../domain/shipping_rates.ts";
import type { FetchShippingRatesError } from "./shipping_rate_error.ts";

export type ShippingRatePort = Readonly<{
  fetchShippingRates: (
    shipment: Shipment,
  ) => Promise<Result<FetchShippingRatesError, ShippingRates>>;
}>;
