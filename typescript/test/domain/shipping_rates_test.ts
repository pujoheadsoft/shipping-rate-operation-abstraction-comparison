import { expect, test } from "@jest/globals";
import {
  findCheapestShippingRate,
  type ShippingRates,
} from "../../src/domain/shipping_rates.ts";

test("一番安い送料を返す", () => {
  const rates: ShippingRates = [
    { carrier: "配送業者X", amount: 200 },
    { carrier: "配送業者Y", amount: 100 },
    { carrier: "配送業者Z", amount: 300 },
  ];

  expect(findCheapestShippingRate(rates)).toEqual({
    carrier: "配送業者Y",
    amount: 100,
  });
});

test("最安が複数あるなら最初に見つかったものを返す", () => {
  const rates: ShippingRates = [
    { carrier: "配送業者X", amount: 200 },
    { carrier: "配送業者Y", amount: 100 },
    { carrier: "配送業者Z", amount: 100 },
  ];

  expect(findCheapestShippingRate(rates)).toEqual({
    carrier: "配送業者Y",
    amount: 100,
  });
});
