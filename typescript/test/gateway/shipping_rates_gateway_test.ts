import { expect, jest, test } from "@jest/globals";
import { error, ok } from "../../src/data/result.ts";
import type { ShippingRates } from "../../src/domain/shipping_rates.ts";
import { type Dependencies, fetchShippingRates } from "../../src/gateway/shipping_rates_gateway.ts";
import { FetchShippingRatesFailed } from "../../src/port/shipping_rate_error.ts";

test("3社へリクエストを送り、すべての送料を取得できる", async () => {
  const shipment = { destinationPostalCode: "111-1111", weight: 1000 };

  const deps: jest.Mocked<Dependencies> = {
    carrierXApiClient: { fetchRate: jest.fn() },
    carrierYApiClient: { fetchRate: jest.fn() },
    carrierZApiClient: { fetchRate: jest.fn() },
  };
  const requestX = { destination: "111-1111", weightGrams: 1000 };
  const requestY = { postalCode: "111-1111", weight: 1000 };
  const requestZ = { postalCode: "111-1111", weight: 1000 };
  const responseX = { amount: 1000, serviceCode: "EXPRESS" };
  const responseY = { price: 2000, serviceName: "Standard Delivery" };
  const responseZ = { amount: 3000, serviceCode: "ECONOMY" };
  deps.carrierXApiClient.fetchRate.whenCalledWith(requestX).mockResolvedValue(responseX);
  deps.carrierYApiClient.fetchRate.whenCalledWith(requestY).mockResolvedValue(responseY);
  deps.carrierZApiClient.fetchRate.whenCalledWith(requestZ).mockResolvedValue(responseZ);

  const expectedRates: ShippingRates = [
    { carrier: "CarrierX", amount: 1000 },
    { carrier: "CarrierY", amount: 2000 },
    { carrier: "CarrierZ", amount: 3000 },
  ];
  const expected = ok(expectedRates);
  const actual = await fetchShippingRates(deps)(shipment);

  expect(actual).toEqual(expected);
});

test("Carrierで例外が発生した場合は送料取得エラーを返す", async () => {
  const shipment = { destinationPostalCode: "111-1111", weight: 1000 };

  const deps: jest.Mocked<Dependencies> = {
    carrierXApiClient: { fetchRate: jest.fn() },
    carrierYApiClient: { fetchRate: jest.fn() },
    carrierZApiClient: { fetchRate: jest.fn() },
  };
  const requestX = { destination: "111-1111", weightGrams: 1000 };
  const requestY = { postalCode: "111-1111", weight: 1000 };
  const requestZ = { postalCode: "111-1111", weight: 1000 };
  const responseX = { amount: 1000, serviceCode: "EXPRESS" };
  const responseZ = { amount: 3000, serviceCode: "ECONOMY" };
  const failure = new Error("Carrier Y failed");
  deps.carrierXApiClient.fetchRate.whenCalledWith(requestX).mockResolvedValue(responseX);
  deps.carrierYApiClient.fetchRate.whenCalledWith(requestY).mockRejectedValue(failure);
  deps.carrierZApiClient.fetchRate.whenCalledWith(requestZ).mockResolvedValue(responseZ);

  const expected = error(FetchShippingRatesFailed);
  const actual = await fetchShippingRates(deps)(shipment);

  expect(actual).toEqual(expected);
});
