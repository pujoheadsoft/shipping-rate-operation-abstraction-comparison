export type CarrierZRateRequest = Readonly<{
  postalCode: string;
  weight: number;
}>;

export type CarrierZRateResponse = Readonly<{
  amount: number;
  serviceCode: string;
}>;

export type CarrierZApiClient = Readonly<{
  fetchRate: (
    request: CarrierZRateRequest,
  ) => Promise<CarrierZRateResponse>;
}>;
