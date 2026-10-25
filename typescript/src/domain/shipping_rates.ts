import type { ShippingRate } from "./shipping_rate.ts";

export type NonEmptyArray<A> = readonly [A, ...A[]];

export type ShippingRates = NonEmptyArray<ShippingRate>;

export const findCheapestShippingRate = (
  [first, ...rest]: ShippingRates,
): ShippingRate => rest.reduce(
  (cheapest, rate) => rate.amount < cheapest.amount ? rate : cheapest,
  first,
);
