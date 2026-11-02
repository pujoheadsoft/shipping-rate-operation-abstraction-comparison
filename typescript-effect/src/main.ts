import { Effect, Layer } from "effect";
import type { ShippingRate } from "./domain/shipping_rate.ts";
import { CarrierXApiClientLive, CarrierXApiEnvironment } from "./driver/carrier_x_api_client_driver.ts";
import { CarrierYApiClientLive, CarrierYApiEnvironment } from "./driver/carrier_y_api_client_driver.ts";
import { CarrierZApiClientLive, CarrierZApiEnvironment } from "./driver/carrier_z_api_client_driver.ts";
import { HttpClientLive } from "./driver/http_client.ts";
import { UserApiClientLive, UserApiEnvironment } from "./driver/user_api_client_driver.ts";
import { PostalCodeGatewayLive } from "./gateway/postal_code_gateway.ts";
import { ShippingRatesGatewayLive } from "./gateway/shipping_rates_gateway.ts";
import { getCheapestShippingRate, ShippingDestinationNotFound } from "./usecase/get_cheapest_shipping_rate.ts";

const getEnv = (name: string, defaultValue: string): string => process.env[name] ?? defaultValue;

const CarrierXDependenciesLive: Layer.Layer<CarrierXApiEnvironment> = Layer.succeed(CarrierXApiEnvironment, {
  baseUrl: getEnv("CARRIER_X_API_BASE_URL", "http://localhost:8082"),
});

const CarrierYDependenciesLive: Layer.Layer<CarrierYApiEnvironment> = Layer.succeed(CarrierYApiEnvironment, {
  baseUrl: getEnv("CARRIER_Y_API_BASE_URL", "http://localhost:8083"),
});

const CarrierZDependenciesLive: Layer.Layer<CarrierZApiEnvironment> = Layer.succeed(CarrierZApiEnvironment, {
  baseUrl: getEnv("CARRIER_Z_API_BASE_URL", "http://localhost:8084"),
});

const UserApiDependenciesLive = Layer.merge(
  Layer.succeed(UserApiEnvironment, {
    baseUrl: getEnv("USER_API_BASE_URL", "http://localhost:8081"),
  }),
  HttpClientLive,
);

const CarrierApiDependenciesLive = Layer.mergeAll(
  CarrierXDependenciesLive,
  CarrierYDependenciesLive,
  CarrierZDependenciesLive,
  HttpClientLive,
);

const CarrierClientsLive = Layer.mergeAll(CarrierXApiClientLive, CarrierYApiClientLive, CarrierZApiClientLive).pipe(
  Layer.provide(CarrierApiDependenciesLive),
);

const UserApiClientLayer = UserApiClientLive.pipe(Layer.provide(UserApiDependenciesLive));
const ApplicationLive = Layer.merge(
  ShippingRatesGatewayLive.pipe(Layer.provide(CarrierClientsLive)),
  PostalCodeGatewayLive.pipe(Layer.provide(UserApiClientLayer)),
);

function printShippingRate(rate: ShippingRate): void {
  console.log("一番安い送料の取得に成功しました。");
  console.log(`  ${rate.carrier}: ${rate.amount}円`);
}

const main = getCheapestShippingRate("user-123", 1000).pipe(
  Effect.provide(ApplicationLive),
  Effect.match({
    onFailure: (error) =>
      console.error(
        error instanceof ShippingDestinationNotFound
          ? "配送先が登録されていません。"
          : "一番安い送料の取得に失敗しました。",
      ),
    onSuccess: printShippingRate,
  }),
);

await Effect.runPromise(main);
