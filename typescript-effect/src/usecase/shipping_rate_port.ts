import { Context, type Effect } from "effect";
import type { Shipment } from "../domain/shipment.ts";
import type { ShippingRates } from "../domain/shipping_rates.ts";

export class FetchShippingRatesFailed {
  readonly _tag = "FetchShippingRatesFailed";
}

export class ShippingRatePort extends Context.Service<
  ShippingRatePort,
  {
    readonly fetchShippingRates: (shipment: Shipment) => Effect.Effect<ShippingRates, FetchShippingRatesFailed>;
  }
>()("rates/usecase/ShippingRatePort") {}
