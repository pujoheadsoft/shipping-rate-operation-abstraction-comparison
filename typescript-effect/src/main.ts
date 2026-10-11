import { Effect, Layer } from "effect";
import { CarrierXApiClientLive, CarrierXApiEnvironment } from "./driver/carrier_x_api_client_driver.ts";
import { CarrierYApiClientLive, CarrierYApiEnvironment } from "./driver/carrier_y_api_client_driver.ts";
import { CarrierZApiClientLive, CarrierZApiEnvironment } from "./driver/carrier_z_api_client_driver.ts";
import { HttpClientLive } from "./driver/http_client.ts";
import type { ShippingRates } from "./domain/shipping_rates.ts";
import { ShippingRatesGatewayLive } from "./gateway/shipping_rates_gateway.ts";
import { getShippingRates } from "./usecase/get_shipping_rates.ts";

const CarrierXDependenciesLive: Layer.Layer<CarrierXApiEnvironment> = Layer.succeed(CarrierXApiEnvironment, {
  baseUrl: "https://carrier-x.example.com",
});

const CarrierYDependenciesLive: Layer.Layer<CarrierYApiEnvironment> = Layer.succeed(CarrierYApiEnvironment, {
  baseUrl: "https://carrier-y.example.com",
});

const CarrierZDependenciesLive: Layer.Layer<CarrierZApiEnvironment> = Layer.succeed(CarrierZApiEnvironment, {
  baseUrl: "https://carrier-z.example.com",
});

const CarrierApiDependenciesLive = Layer.mergeAll(
  CarrierXDependenciesLive,
  CarrierYDependenciesLive,
  CarrierZDependenciesLive,
  HttpClientLive,
);

const CarrierClientsLive = Layer.mergeAll(CarrierXApiClientLive, CarrierYApiClientLive, CarrierZApiClientLive).pipe(
  Layer.provide(CarrierApiDependenciesLive),
);

const ApplicationLive = ShippingRatesGatewayLive.pipe(Layer.provide(CarrierClientsLive));

function printShippingRates(rates: ShippingRates): void {
  console.log("送料の取得に成功しました。");
  for (const rate of rates) {
    console.log(`  ${rate.carrier}: ${rate.amount}円`);
  }
}

const main = getShippingRates({ destinationPostalCode: "111-1111", weight: 1000 }).pipe(
  Effect.provide(ApplicationLive),
  Effect.match({
    onFailure: () => console.error("送料の取得に失敗しました。配送業者から送料を取得できませんでした。"),
    onSuccess: printShippingRates,
  }),
);

await Effect.runPromise(main);
