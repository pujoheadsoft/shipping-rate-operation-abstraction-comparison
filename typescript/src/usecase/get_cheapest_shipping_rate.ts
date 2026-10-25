import { error, ok, type Result } from "../data/result.ts";
import type { ShippingRate } from "../domain/shipping_rate.ts";
import { findCheapestShippingRate } from "../domain/shipping_rates.ts";
import type { UserId } from "../domain/user_id.ts";
import type { Weight } from "../domain/weight.ts";
import { PostalCodeNotFound } from "../port/postal_code_error.ts";
import type { PostalCodePort } from "../port/postal_code_port.ts";
import type { ShippingRatePort } from "../port/shipping_rate_port.ts";
import {
  GetCheapestShippingRateFailed,
  type GetCheapestShippingRateError,
  ShippingDestinationNotFound,
} from "./get_cheapest_shipping_rate_error.ts";

export type GetCheapestShippingRateDependencies = Readonly<{
  postalCodePort: PostalCodePort;
  shippingRatePort: ShippingRatePort;
}>;

export type GetCheapestShippingRateInput = Readonly<{
  userId: UserId;
  weight: Weight;
}>;

type GetCheapestShippingRateResult = Result<
  GetCheapestShippingRateError,
  ShippingRate
>;

export const getCheapestShippingRate = (
  dependencies: GetCheapestShippingRateDependencies,
) => async (
  input: GetCheapestShippingRateInput,
): Promise<GetCheapestShippingRateResult> => {
  const postalCodeResult = await dependencies.postalCodePort
    .fetchPostalCodeByUserId(input.userId);

  if (postalCodeResult.type === "error") {
    return error(
      postalCodeResult.error === PostalCodeNotFound
        ? ShippingDestinationNotFound
        : GetCheapestShippingRateFailed,
    );
  }

  const ratesResult = await dependencies.shippingRatePort.fetchShippingRates({
    destinationPostalCode: postalCodeResult.value,
    weight: input.weight,
  });

  return ratesResult.type === "error"
    ? error(GetCheapestShippingRateFailed)
    : ok(findCheapestShippingRate(ratesResult.value));
};
