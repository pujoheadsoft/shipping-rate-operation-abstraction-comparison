import type { ShippingRate } from "./shipping_rate.ts";

export type ShippingRates = readonly [ShippingRate, ...ShippingRate[]];
