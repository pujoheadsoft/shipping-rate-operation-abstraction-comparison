export const ShippingDestinationNotFound = "ShippingDestinationNotFound" as const;
export const GetCheapestShippingRateFailed = "GetCheapestShippingRateFailed" as const;

export type GetCheapestShippingRateError =
  | typeof ShippingDestinationNotFound
  | typeof GetCheapestShippingRateFailed;
