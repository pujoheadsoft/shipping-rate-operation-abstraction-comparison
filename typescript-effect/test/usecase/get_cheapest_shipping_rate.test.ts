import assert from "node:assert/strict";
import { test } from "node:test";
import { Effect } from "effect";
import {
  GetCheapestShippingRateFailed,
  getCheapestShippingRate,
  ShippingDestinationNotFound,
} from "../../src/usecase/get_cheapest_shipping_rate.ts";
import { FetchPostalCodeFailed, PostalCodeNotFound, PostalCodePort } from "../../src/usecase/postal_code_port.ts";
import { FetchShippingRatesFailed, ShippingRatePort } from "../../src/usecase/shipping_rate_port.ts";

const result = (postalCode: Effect.Effect<string, PostalCodeNotFound | FetchPostalCodeFailed>, fetchRates: () => any) =>
  getCheapestShippingRate("user-123", 1000).pipe(
    Effect.provideService(PostalCodePort, { fetchPostalCodeByUserId: () => postalCode }),
    Effect.provideService(ShippingRatePort, { fetchShippingRates: fetchRates }),
    Effect.match({ onFailure: (error) => error, onSuccess: (rate) => rate }),
    Effect.runPromise,
  );

test("ユーザーの配送先に対する最安送料を返す", async () => {
  const actual = await result(Effect.succeed("111-1111"), () =>
    Effect.succeed([
      { carrier: "X", amount: 300 },
      { carrier: "Y", amount: 200 },
    ]),
  );
  assert.deepEqual(actual, { carrier: "Y", amount: 200 });
});

test("郵便番号がなければ送料Portを呼ばない", async () => {
  let called = false;
  const actual = await result(Effect.fail(new PostalCodeNotFound()), () => {
    called = true;
    return Effect.fail(new FetchShippingRatesFailed());
  });
  assert.deepEqual(actual, new ShippingDestinationNotFound());
  assert.equal(called, false);
});

test("郵便番号取得失敗をユースケース失敗へ変換する", async () => {
  const actual = await result(Effect.fail(new FetchPostalCodeFailed()), () => Effect.die("must not run"));
  assert.deepEqual(actual, new GetCheapestShippingRateFailed());
});

test("送料取得失敗をユースケース失敗へ変換する", async () => {
  const actual = await result(Effect.succeed("111-1111"), () => Effect.fail(new FetchShippingRatesFailed()));
  assert.deepEqual(actual, new GetCheapestShippingRateFailed());
});
