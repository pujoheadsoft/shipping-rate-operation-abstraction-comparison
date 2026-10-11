import { Context, type Effect } from "effect";

export type CarrierYRateRequest = Readonly<{
  postalCode: string;
  weight: number;
}>;

export type CarrierYRateResponse = Readonly<{
  price: number;
  serviceName: string;
}>;

export class CarrierYApiOperationFailed {
  readonly _tag = "CarrierYApiOperationFailed";
}

export class CarrierYApiClient extends Context.Service<
  CarrierYApiClient,
  {
    readonly fetchRate: (
      request: CarrierYRateRequest,
    ) => Effect.Effect<CarrierYRateResponse, CarrierYApiOperationFailed>;
  }
>()("rates/gateway/CarrierYApiClient") {}
