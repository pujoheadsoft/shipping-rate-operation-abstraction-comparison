import assert from "node:assert/strict";
import { test } from "node:test";
import { Effect, Layer } from "effect";
import type { ShippingRates } from "../../src/domain/shipping_rates.ts";
import { CarrierXApiClient, CarrierXApiOperationFailed } from "../../src/gateway/carrier_x_api_client.ts";
import { CarrierYApiClient } from "../../src/gateway/carrier_y_api_client.ts";
import { CarrierZApiClient } from "../../src/gateway/carrier_z_api_client.ts";
import { ShippingRatesGatewayLive } from "../../src/gateway/shipping_rates_gateway.ts";
import { FetchShippingRatesFailed, ShippingRatePort } from "../../src/usecase/shipping_rate_port.ts";

const shipment = { destinationPostalCode: "111-1111", weight: 1000 };

test("3社へリクエストを送り、すべての送料を取得できる", async () => {
  const expected: ShippingRates = [
    { carrier: "CarrierX", amount: 1000 },
    { carrier: "CarrierY", amount: 2000 },
    { carrier: "CarrierZ", amount: 3000 },
  ];
  const carrierClients = Layer.mergeAll(
    Layer.succeed(CarrierXApiClient, {
      fetchRate: (request) => {
        assert.deepEqual(request, { destination: "111-1111", weightGrams: 1000 });
        return Effect.succeed({ amount: 1000, serviceCode: "EXPRESS" });
      },
    }),
    Layer.succeed(CarrierYApiClient, {
      fetchRate: (request) => {
        assert.deepEqual(request, { postalCode: "111-1111", weight: 1000 });
        return Effect.succeed({ price: 2000, serviceName: "Standard Delivery" });
      },
    }),
    Layer.succeed(CarrierZApiClient, {
      fetchRate: (request) => {
        assert.deepEqual(request, { postalCode: "111-1111", weight: 1000 });
        return Effect.succeed({ amount: 3000, serviceCode: "ECONOMY" });
      },
    }),
  );
  const gateway = ShippingRatesGatewayLive.pipe(Layer.provide(carrierClients));

  const actual = await Effect.runPromise(
    ShippingRatePort.use((port) => port.fetchShippingRates(shipment)).pipe(Effect.provide(gateway)),
  );

  assert.deepEqual(actual, expected);
});

test("Carrierで失敗した場合は送料取得エラーを返す", async () => {
  const carrierClients = Layer.mergeAll(
    Layer.succeed(CarrierXApiClient, {
      fetchRate: () => Effect.fail(new CarrierXApiOperationFailed()),
    }),
    Layer.succeed(CarrierYApiClient, {
      fetchRate: () => Effect.succeed({ price: 2000, serviceName: "Standard Delivery" }),
    }),
    Layer.succeed(CarrierZApiClient, {
      fetchRate: () => Effect.succeed({ amount: 3000, serviceCode: "ECONOMY" }),
    }),
  );
  const gateway = ShippingRatesGatewayLive.pipe(Layer.provide(carrierClients));

  const actual = await Effect.runPromise(
    ShippingRatePort.use((port) => port.fetchShippingRates(shipment)).pipe(
      Effect.provide(gateway),
      Effect.match({
        onFailure: (error) => error,
        onSuccess: () => undefined,
      }),
    ),
  );

  assert.deepEqual(actual, new FetchShippingRatesFailed());
});
