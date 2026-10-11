import { Context, type Effect } from "effect";

export type CarrierXRateRequest = Readonly<{
  destination: string;
  weightGrams: number;
}>;

export type CarrierXRateResponse = Readonly<{
  amount: number;
  serviceCode: string;
}>;

export class CarrierXApiOperationFailed {
  readonly _tag = "CarrierXApiOperationFailed";
}

export class CarrierXApiClient extends Context.Service<
  CarrierXApiClient,
  {
    readonly fetchRate: (
      request: CarrierXRateRequest,
    ) => Effect.Effect<CarrierXRateResponse, CarrierXApiOperationFailed>;
  }
>()("rates/gateway/CarrierXApiClient") {}
