import { Context, Effect, Layer } from "effect";
import {
  CarrierZApiClient,
  CarrierZApiOperationFailed,
  type CarrierZRateRequest,
  type CarrierZRateResponse,
} from "../gateway/carrier_z_api_client.ts";
import { decodeJson } from "./decode_json.ts";
import { DriverOperationFailed } from "./driver_error.ts";
import { HttpClient } from "./http_client.ts";

export class CarrierZApiEnvironment extends Context.Service<CarrierZApiEnvironment, Readonly<{ baseUrl: string }>>()(
  "rates/driver/CarrierZApiEnvironment",
) {}

export const CarrierZApiClientLive: Layer.Layer<CarrierZApiClient, never, CarrierZApiEnvironment | HttpClient> =
  Layer.effect(
    CarrierZApiClient,
    Effect.gen(function* () {
      const environment = yield* CarrierZApiEnvironment;
      const httpClient = yield* HttpClient;

      return {
        fetchRate: (
          request: CarrierZRateRequest,
        ): Effect.Effect<CarrierZRateResponse, CarrierZApiOperationFailed, never> =>
          performFetchRate(request).pipe(
            Effect.provideService(CarrierZApiEnvironment, environment),
            Effect.provideService(HttpClient, httpClient),
            Effect.mapError(() => new CarrierZApiOperationFailed()),
          ),
      } satisfies Context.Service.Shape<typeof CarrierZApiClient>;
    }),
  );

const performFetchRate = (
  request: CarrierZRateRequest,
): Effect.Effect<CarrierZRateResponse, DriverOperationFailed, CarrierZApiEnvironment | HttpClient> =>
  Effect.gen(function* () {
    const environment = yield* CarrierZApiEnvironment;
    const httpClient = yield* HttpClient;

    const body = yield* httpClient.post(`${environment.baseUrl}/shipping/quote`, JSON.stringify(request));

    return yield* decodeJson(body, isCarrierZRateResponse, () => new DriverOperationFailed());
  }).pipe(Effect.mapError(() => new DriverOperationFailed()));

const isCarrierZRateResponse = (value: unknown): value is CarrierZRateResponse =>
  typeof value === "object" &&
  value !== null &&
  typeof (value as CarrierZRateResponse).amount === "number" &&
  typeof (value as CarrierZRateResponse).serviceCode === "string";
