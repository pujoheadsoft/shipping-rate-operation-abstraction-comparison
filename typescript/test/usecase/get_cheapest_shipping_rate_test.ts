import { expect, jest, test } from "@jest/globals";
import { error, ok } from "../../src/data/result.ts";
import type { ShippingRates } from "../../src/domain/shipping_rates.ts";
import {
  FetchPostalCodeFailed,
  PostalCodeNotFound,
} from "../../src/port/postal_code_error.ts";
import { FetchShippingRatesFailed } from "../../src/port/shipping_rate_error.ts";
import {
  getCheapestShippingRate,
  type GetCheapestShippingRateDependencies,
} from "../../src/usecase/get_cheapest_shipping_rate.ts";
import {
  GetCheapestShippingRateFailed,
  ShippingDestinationNotFound,
} from "../../src/usecase/get_cheapest_shipping_rate_error.ts";

const createDependencies = (): jest.Mocked<GetCheapestShippingRateDependencies> => ({
  postalCodePort: { fetchPostalCodeByUserId: jest.fn() },
  shippingRatePort: { fetchShippingRates: jest.fn() },
});

test("ユーザーの配送先に対する一番安い送料を取得できる", async () => {
  const dependencies = createDependencies();
  const rates: ShippingRates = [
    { carrier: "配送業者X", amount: 200 },
    { carrier: "配送業者Y", amount: 100 },
    { carrier: "配送業者Z", amount: 300 },
  ];
  dependencies.postalCodePort.fetchPostalCodeByUserId
    .whenCalledWith("userId")
    .mockResolvedValue(ok("111-1111"));
  dependencies.shippingRatePort.fetchShippingRates
    .whenCalledWith({ destinationPostalCode: "111-1111", weight: 500 })
    .mockResolvedValue(ok(rates));

  const actual = await getCheapestShippingRate(dependencies)({
    userId: "userId",
    weight: 500,
  });

  expect(actual).toEqual(ok({ carrier: "配送業者Y", amount: 100 }));
});

test("郵便番号の取得に失敗したらGetCheapestShippingRateFailedを返す", async () => {
  const dependencies = createDependencies();
  dependencies.postalCodePort.fetchPostalCodeByUserId
    .mockResolvedValue(error(FetchPostalCodeFailed));

  const actual = await getCheapestShippingRate(dependencies)({
    userId: "userId",
    weight: 500,
  });

  expect(actual).toEqual(error(GetCheapestShippingRateFailed));
  expect(dependencies.shippingRatePort.fetchShippingRates).not.toHaveBeenCalled();
});

test("郵便番号が存在しなければShippingDestinationNotFoundを返す", async () => {
  const dependencies = createDependencies();
  dependencies.postalCodePort.fetchPostalCodeByUserId
    .mockResolvedValue(error(PostalCodeNotFound));

  const actual = await getCheapestShippingRate(dependencies)({
    userId: "unknown",
    weight: 500,
  });

  expect(actual).toEqual(error(ShippingDestinationNotFound));
  expect(dependencies.shippingRatePort.fetchShippingRates).not.toHaveBeenCalled();
});

test("送料の取得に失敗したらGetCheapestShippingRateFailedを返す", async () => {
  const dependencies = createDependencies();
  dependencies.postalCodePort.fetchPostalCodeByUserId
    .mockResolvedValue(ok("111-1111"));
  dependencies.shippingRatePort.fetchShippingRates
    .mockResolvedValue(error(FetchShippingRatesFailed));

  const actual = await getCheapestShippingRate(dependencies)({
    userId: "userId",
    weight: 500,
  });

  expect(actual).toEqual(error(GetCheapestShippingRateFailed));
});
