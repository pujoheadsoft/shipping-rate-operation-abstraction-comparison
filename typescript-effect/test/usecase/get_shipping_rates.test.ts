import assert from "node:assert/strict";
import { test } from "node:test";
import { Effect } from "effect";
import type { Shipment } from "../../src/domain/shipment.ts";
import type { ShippingRates } from "../../src/domain/shipping_rates.ts";
import { GetShippingRatesFailed, getShippingRates } from "../../src/usecase/get_shipping_rates.ts";
import { FetchShippingRatesFailed, ShippingRatePort } from "../../src/usecase/shipping_rate_port.ts";

const shipment: Shipment = {
  destinationPostalCode: "111-1111",
  weight: 10,
};

test("荷物に対しての送料をすべて取得できる", async () => {
  const expected: ShippingRates = [{ carrier: "Carrier X", amount: 100 }];
  const actual = await Effect.runPromise(
    getShippingRates(shipment).pipe(
      Effect.provideService(ShippingRatePort, {
        fetchShippingRates: () => Effect.succeed(expected),
      }),
    ),
  );

  assert.deepEqual(actual, expected);
});

test("送料取得エラーが起きた場合はエラーが返る", async () => {
  const actual = await Effect.runPromise(
    getShippingRates(shipment).pipe(
      Effect.provideService(ShippingRatePort, {
        fetchShippingRates: () => Effect.fail(new FetchShippingRatesFailed()),
      }),
      Effect.match({
        onFailure: (error) => error,
        onSuccess: () => undefined,
      }),
    ),
  );

  assert.deepEqual(actual, new GetShippingRatesFailed());
});
