import { expect, jest, test } from "@jest/globals";
import { ok } from "../../src/data/result.ts";
import { type Dependencies, fetchShippingRates } from "../../src/gateway/shipping_rates_gateway.ts";

const deferred = <T>() => {
  let resolve!: (value: T) => void;
  const promise = new Promise<T>((done) => {
    resolve = done;
  });
  return { promise, resolve };
};

test("3社のPromiseが重なり、X/Y/Z順の結果を返す", async () => {
  const started = deferred<void>();
  const release = deferred<void>();
  let startedCount = 0;
  const gate = <T>(value: T): Promise<T> => {
    startedCount += 1;
    if (startedCount === 3) started.resolve();
    return release.promise.then(() => value);
  };
  const dependencies: jest.Mocked<Dependencies> = {
    carrierXApiClient: { fetchRate: jest.fn(() => gate({ amount: 1, serviceCode: "EXPRESS" })) },
    carrierYApiClient: { fetchRate: jest.fn(() => gate({ price: 2, serviceName: "Standard Delivery" })) },
    carrierZApiClient: { fetchRate: jest.fn(() => gate({ amount: 3, serviceCode: "ECONOMY" })) },
  };
  let timeoutId: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timeoutId = setTimeout(() => reject(new Error("3社が並行に開始されなかった")), 2000);
  });
  const result = fetchShippingRates(dependencies)({ destinationPostalCode: "111-1111", weight: 1000 });

  try {
    await Promise.race([started.promise, timeout]);
    release.resolve();
    await expect(result).resolves.toEqual(ok([
      { carrier: "CarrierX", amount: 1 },
      { carrier: "CarrierY", amount: 2 },
      { carrier: "CarrierZ", amount: 3 },
    ]));
  } finally {
    if (timeoutId !== undefined) clearTimeout(timeoutId);
    release.resolve();
  }
});
