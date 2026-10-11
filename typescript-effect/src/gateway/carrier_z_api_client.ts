import { Context, type Effect } from "effect";

export type CarrierZRateRequest = Readonly<{
  postalCode: string;
  weight: number;
}>;

export type CarrierZRateResponse = Readonly<{
  amount: number;
  serviceCode: string;
}>;

export class CarrierZApiOperationFailed {
  readonly _tag = "CarrierZApiOperationFailed";
}

export class CarrierZApiClient extends Context.Service<
  CarrierZApiClient,
  {
    readonly fetchRate: (
      request: CarrierZRateRequest,
    ) => Effect.Effect<CarrierZRateResponse, CarrierZApiOperationFailed>;
  }
>()("rates/gateway/CarrierZApiClient") {}
