import type { ShippingRate } from "./shipping_rate.ts";

type NonEmptyArray<T> = readonly [T, ...T[]];

export class ShippingRates {
  constructor(readonly values: NonEmptyArray<ShippingRate>) {}
}
