import { Context, Effect, Layer } from "effect";
import {
  CarrierXApiClient,
  CarrierXApiOperationFailed,
  type CarrierXRateRequest,
  type CarrierXRateResponse,
} from "../gateway/carrier_x_api_client.ts";
import { decodeJson } from "./decode_json.ts";
import { DriverOperationFailed } from "./driver_error.ts";
import { HttpClient } from "./http_client.ts";

export class CarrierXApiEnvironment extends Context.Service<CarrierXApiEnvironment, Readonly<{ baseUrl: string }>>()(
  "rates/driver/CarrierXApiEnvironment",
) {}

export const CarrierXApiClientLive: Layer.Layer<CarrierXApiClient, never, CarrierXApiEnvironment | HttpClient> =
  Layer.effect(
    CarrierXApiClient,
    Effect.gen(function* () {
      const environment = yield* CarrierXApiEnvironment;
      const httpClient = yield* HttpClient;

      return {
        fetchRate: (
          request: CarrierXRateRequest,
        ): Effect.Effect<CarrierXRateResponse, CarrierXApiOperationFailed, never> =>
          performFetchRate(request).pipe(
            Effect.provideService(CarrierXApiEnvironment, environment),
            Effect.provideService(HttpClient, httpClient),
            Effect.mapError(() => new CarrierXApiOperationFailed()),
          ),
      } satisfies Context.Service.Shape<typeof CarrierXApiClient>;
    }),
  );

const performFetchRate = (
  request: CarrierXRateRequest,
): Effect.Effect<CarrierXRateResponse, DriverOperationFailed, CarrierXApiEnvironment | HttpClient> =>
  Effect.gen(function* () {
    const environment = yield* CarrierXApiEnvironment;
    const httpClient = yield* HttpClient;

    const body = yield* httpClient.post(`${environment.baseUrl}/shipping-rates`, JSON.stringify(request));

    return yield* decodeJson(body, isCarrierXRateResponse, () => new DriverOperationFailed());
  }).pipe(Effect.mapError(() => new DriverOperationFailed()));

const isCarrierXRateResponse = (value: unknown): value is CarrierXRateResponse =>
  typeof value === "object" &&
  value !== null &&
  typeof (value as CarrierXRateResponse).amount === "number" &&
  typeof (value as CarrierXRateResponse).serviceCode === "string";
