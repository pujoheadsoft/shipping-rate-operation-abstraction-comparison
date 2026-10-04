import { expect, jest, test } from "@jest/globals";
import { error, ok } from "../../src/data/result.ts";
import type { Shipment } from "../../src/domain/shipment.ts";
import type { ShippingRates } from "../../src/domain/shipping_rates.ts";
import { FetchShippingRatesFailed } from "../../src/port/shipping_rate_error.ts";
import type { ShippingRatePort } from "../../src/port/shipping_rate_port.ts";
import { getShippingRates } from "../../src/usecase/get_shipping_rates.ts";
import { GetShippingRatesFailed } from "../../src/usecase/get_shipping_rates_error.ts";

test("荷物に対しての送料をすべて取得できる", async () => {
  const shipment: Shipment = { destinationPostalCode: "111-1111", weight: 10 };
  const rates: ShippingRates = [{ carrier: "Carrier X", amount: 100 }];
  const expected = ok(rates);
  const port: jest.Mocked<ShippingRatePort> = { fetchShippingRates: jest.fn() };

  port.fetchShippingRates.whenCalledWith(shipment).mockResolvedValue(expected);

  const actual = await getShippingRates(port)(shipment);

  expect(actual).toEqual(expected);
});

test("送料取得エラーが起きた場合はエラーが返る", async () => {
  const shipment: Shipment = { destinationPostalCode: "111-1111", weight: 10 };
  const failure = error(FetchShippingRatesFailed);
  const expected = error(GetShippingRatesFailed);
  const port: jest.Mocked<ShippingRatePort> = { fetchShippingRates: jest.fn() };

  port.fetchShippingRates.whenCalledWith(shipment).mockResolvedValue(failure);

  const actual = await getShippingRates(port)(shipment);

  expect(actual).toEqual(expected);
});
