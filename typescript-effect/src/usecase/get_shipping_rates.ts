import { Effect } from "effect";
import type { Shipment } from "../domain/shipment.ts";
import type { ShippingRates } from "../domain/shipping_rates.ts";
import { ShippingRatePort } from "./shipping_rate_port.ts";

export class GetShippingRatesFailed {
  readonly _tag = "GetShippingRatesFailed";
}

export const getShippingRates = (
  shipment: Shipment,
): Effect.Effect<ShippingRates, GetShippingRatesFailed, ShippingRatePort> =>
  ShippingRatePort.use((port) => port.fetchShippingRates(shipment)).pipe(
    Effect.mapError(() => new GetShippingRatesFailed()),
  );
