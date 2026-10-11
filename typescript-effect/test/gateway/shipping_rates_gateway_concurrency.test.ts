import assert from "node:assert/strict";
import { test } from "node:test";
import { Deferred, Effect, Fiber, Layer } from "effect";
import {
  CarrierXApiClient,
  CarrierXApiOperationFailed,
  type CarrierXRateResponse,
} from "../../src/gateway/carrier_x_api_client.ts";
import { CarrierYApiClient, type CarrierYRateResponse } from "../../src/gateway/carrier_y_api_client.ts";
import { CarrierZApiClient, type CarrierZRateResponse } from "../../src/gateway/carrier_z_api_client.ts";
import { ShippingRatesGatewayLive } from "../../src/gateway/shipping_rates_gateway.ts";
import { FetchShippingRatesFailed, ShippingRatePort } from "../../src/usecase/shipping_rate_port.ts";

const shipment = { destinationPostalCode: "111-1111", weight: 1000 };

test("3社のEffectが重なり、X/Y/Z順の結果を返す", { timeout: 2000 }, async () => {
  const allStarted = Deferred.makeUnsafe<void>();
  const release = Deferred.makeUnsafe<void>();
  let startedCount = 0;

  const gate = <A>(value: A): Effect.Effect<A> =>
    Effect.gen(function* () {
      startedCount += 1;
      if (startedCount === 3) {
        yield* Deferred.succeed(allStarted, undefined);
      }
      yield* Deferred.await(release);
      return value;
    });

  const carrierClients = Layer.mergeAll(
    Layer.succeed(CarrierXApiClient, {
      fetchRate: () => gate<CarrierXRateResponse>({ amount: 1, serviceCode: "EXPRESS" }),
    }),
    Layer.succeed(CarrierYApiClient, {
      fetchRate: () => gate<CarrierYRateResponse>({ price: 2, serviceName: "Standard Delivery" }),
    }),
    Layer.succeed(CarrierZApiClient, {
      fetchRate: () => gate<CarrierZRateResponse>({ amount: 3, serviceCode: "ECONOMY" }),
    }),
  );
  const gateway = ShippingRatesGatewayLive.pipe(Layer.provide(carrierClients));

  const program = Effect.gen(function* () {
    const fiber = yield* ShippingRatePort.use((port) => port.fetchShippingRates(shipment)).pipe(
      Effect.provide(gateway),
      Effect.forkChild,
    );
    yield* Deferred.await(allStarted);
    yield* Deferred.succeed(release, undefined);
    return yield* Fiber.join(fiber);
  });

  const actual = await Effect.runPromise(program);

  assert.deepEqual(actual, [
    { carrier: "CarrierX", amount: 1 },
    { carrier: "CarrierY", amount: 2 },
    { carrier: "CarrierZ", amount: 3 },
  ]);
});

test("1社が失敗した場合は実行中の残り2社を中断する", { timeout: 2000 }, async () => {
  const allStarted = Deferred.makeUnsafe<void>();
  const releaseFailure = Deferred.makeUnsafe<void>();
  const allInterrupted = Deferred.makeUnsafe<void>();
  let startedCount = 0;
  let interruptedCount = 0;

  const markStarted = Effect.gen(function* () {
    startedCount += 1;
    if (startedCount === 3) {
      yield* Deferred.succeed(allStarted, undefined);
    }
  });
  const markInterrupted = () =>
    Effect.gen(function* () {
      interruptedCount += 1;
      if (interruptedCount === 2) {
        yield* Deferred.succeed(allInterrupted, undefined);
      }
    });
  const waitUntilInterrupted = markStarted.pipe(Effect.andThen(Effect.never), Effect.onInterrupt(markInterrupted));

  const carrierClients = Layer.mergeAll(
    Layer.succeed(CarrierXApiClient, {
      fetchRate: () =>
        markStarted.pipe(
          Effect.andThen(Deferred.await(releaseFailure)),
          Effect.andThen(Effect.fail(new CarrierXApiOperationFailed())),
        ),
    }),
    Layer.succeed(CarrierYApiClient, {
      fetchRate: () => waitUntilInterrupted,
    }),
    Layer.succeed(CarrierZApiClient, {
      fetchRate: () => waitUntilInterrupted,
    }),
  );
  const gateway = ShippingRatesGatewayLive.pipe(Layer.provide(carrierClients));

  const program = Effect.gen(function* () {
    const fiber = yield* ShippingRatePort.use((port) => port.fetchShippingRates(shipment)).pipe(
      Effect.provide(gateway),
      Effect.match({
        onFailure: (error) => error,
        onSuccess: () => undefined,
      }),
      Effect.forkChild,
    );
    yield* Deferred.await(allStarted);
    yield* Deferred.succeed(releaseFailure, undefined);
    const result = yield* Fiber.join(fiber);
    yield* Deferred.await(allInterrupted);
    return result;
  });

  const actual = await Effect.runPromise(program);

  assert.deepEqual(actual, new FetchShippingRatesFailed());
  assert.equal(interruptedCount, 2);
});
