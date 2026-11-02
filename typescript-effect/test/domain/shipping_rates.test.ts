import assert from "node:assert/strict";
import { test } from "node:test";
import { findCheapest, type ShippingRates } from "../../src/domain/shipping_rates.ts";

test("一番安い送料を返し、同額なら先頭を保つ", () => {
  const rates: ShippingRates = [
    { carrier: "X", amount: 50 },
    { carrier: "Y", amount: 30 },
    { carrier: "Z", amount: 30 },
  ];
  assert.deepEqual(findCheapest(rates), { carrier: "Y", amount: 30 });
});
