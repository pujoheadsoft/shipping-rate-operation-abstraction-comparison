export type CarrierXRateRequest = Readonly<{
  destination: string;
  weightGrams: number;
}>;

export type CarrierXRateResponse = Readonly<{
  amount: number;
  serviceCode: string;
}>;

export type CarrierXApiClient = Readonly<{
  fetchRate: (
    request: CarrierXRateRequest,
  ) => Promise<CarrierXRateResponse>;
}>;
