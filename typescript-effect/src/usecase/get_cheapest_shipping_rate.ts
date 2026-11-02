import { Effect } from "effect";
import type { ShippingRate } from "../domain/shipping_rate.ts";
import { findCheapest } from "../domain/shipping_rates.ts";
import type { UserId } from "../domain/user_id.ts";
import type { Weight } from "../domain/weight.ts";
import { PostalCodeNotFound, PostalCodePort } from "./postal_code_port.ts";
import { ShippingRatePort } from "./shipping_rate_port.ts";

export class ShippingDestinationNotFound {
  readonly _tag = "ShippingDestinationNotFound";
}

export class GetCheapestShippingRateFailed {
  readonly _tag = "GetCheapestShippingRateFailed";
}

export const getCheapestShippingRate = (
  userId: UserId,
  weight: Weight,
): Effect.Effect<
  ShippingRate,
  ShippingDestinationNotFound | GetCheapestShippingRateFailed,
  PostalCodePort | ShippingRatePort
> =>
  Effect.gen(function* () {
    const postalCode = yield* PostalCodePort.use((port) => port.fetchPostalCodeByUserId(userId)).pipe(
      Effect.mapError((error) =>
        error instanceof PostalCodeNotFound ? new ShippingDestinationNotFound() : new GetCheapestShippingRateFailed(),
      ),
    );
    const rates = yield* ShippingRatePort.use((port) =>
      port.fetchShippingRates({ destinationPostalCode: postalCode, weight }),
    ).pipe(Effect.mapError(() => new GetCheapestShippingRateFailed()));
    return findCheapest(rates);
  });
