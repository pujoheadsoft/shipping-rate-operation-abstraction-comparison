import { Context, Effect, Layer } from "effect";
import {
  CarrierYApiClient,
  CarrierYApiOperationFailed,
  type CarrierYRateRequest,
  type CarrierYRateResponse,
} from "../gateway/carrier_y_api_client.ts";
import { decodeJson } from "./decode_json.ts";
import { DriverOperationFailed } from "./driver_error.ts";
import { HttpClient } from "./http_client.ts";

export class CarrierYApiEnvironment extends Context.Service<CarrierYApiEnvironment, Readonly<{ baseUrl: string }>>()(
  "rates/driver/CarrierYApiEnvironment",
) {}

export const CarrierYApiClientLive: Layer.Layer<CarrierYApiClient, never, CarrierYApiEnvironment | HttpClient> =
  Layer.effect(
    CarrierYApiClient,
    Effect.gen(function* () {
      const environment = yield* CarrierYApiEnvironment;
      const httpClient = yield* HttpClient;

      return {
        fetchRate: (
          request: CarrierYRateRequest,
        ): Effect.Effect<CarrierYRateResponse, CarrierYApiOperationFailed, never> =>
          performFetchRate(request).pipe(
            Effect.provideService(CarrierYApiEnvironment, environment),
            Effect.provideService(HttpClient, httpClient),
            Effect.mapError(() => new CarrierYApiOperationFailed()),
          ),
      } satisfies Context.Service.Shape<typeof CarrierYApiClient>;
    }),
  );

const performFetchRate = (
  request: CarrierYRateRequest,
): Effect.Effect<CarrierYRateResponse, DriverOperationFailed, CarrierYApiEnvironment | HttpClient> =>
  Effect.gen(function* () {
    const environment = yield* CarrierYApiEnvironment;
    const httpClient = yield* HttpClient;

    const body = yield* httpClient.post(`${environment.baseUrl}/rates/quote`, JSON.stringify(request));

    return yield* decodeJson(body, isCarrierYRateResponse, () => new DriverOperationFailed());
  }).pipe(Effect.mapError(() => new DriverOperationFailed()));

const isCarrierYRateResponse = (value: unknown): value is CarrierYRateResponse =>
  typeof value === "object" &&
  value !== null &&
  typeof (value as CarrierYRateResponse).price === "number" &&
  typeof (value as CarrierYRateResponse).serviceName === "string";
