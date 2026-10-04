import { createCarrierXApiClient } from "./driver/carrier_x_api_client_driver.ts";
import { createCarrierYApiClient } from "./driver/carrier_y_api_client_driver.ts";
import { createCarrierZApiClient } from "./driver/carrier_z_api_client_driver.ts";
import type { ShippingRates } from "./domain/shipping_rates.ts";
import { createShippingRatePort, type Dependencies } from "./gateway/shipping_rates_gateway.ts";
import { getShippingRates } from "./usecase/get_shipping_rates.ts";

const main = async (): Promise<void> => {
  const dependencies: Dependencies = {
    carrierXApiClient: createCarrierXApiClient({
      baseUrl: "https://carrier-x.example.com",
    }),
    carrierYApiClient: createCarrierYApiClient({
      baseUrl: "https://carrier-y.example.com",
    }),
    carrierZApiClient: createCarrierZApiClient({
      baseUrl: "https://carrier-z.example.com",
    }),
  };
  const shipment = { destinationPostalCode: "111-1111", weight: 1000 };
  const port = createShippingRatePort(dependencies);
  const result = await getShippingRates(port)(shipment);

  if (result.type === "error") {
    console.error("送料の取得に失敗しました。配送業者から送料を取得できませんでした。");
    return;
  }

  printShippingRates(result.value);
};

const printShippingRates = (rates: ShippingRates): void => {
  console.log("送料の取得に成功しました。");
  for (const rate of rates) {
    console.log(`  ${rate.carrier}: ${rate.amount}円`);
  }
};

if (import.meta.main) {
  await main();
}
