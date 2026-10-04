import type { ShippingRate } from "./shipping_rate.ts";

export type NonEmptyArray<A> = readonly [A, ...A[]];

export type ShippingRates = NonEmptyArray<ShippingRate>;
