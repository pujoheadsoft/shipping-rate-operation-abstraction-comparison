import type { ShippingRate } from "./shipping_rate.ts";

export type ShippingRates = readonly [ShippingRate, ...ShippingRate[]];

export const findCheapest = ([first, ...rest]: ShippingRates): ShippingRate =>
  rest.reduce((cheapest, rate) => (rate.amount < cheapest.amount ? rate : cheapest), first);
