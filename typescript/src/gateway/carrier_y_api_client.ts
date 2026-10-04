export type CarrierYRateRequest = Readonly<{
  postalCode: string;
  weight: number;
}>;

export type CarrierYRateResponse = Readonly<{
  price: number;
  serviceName: string;
}>;

export type CarrierYApiClient = Readonly<{
  fetchRate: (
    request: CarrierYRateRequest,
  ) => Promise<CarrierYRateResponse>;
}>;
