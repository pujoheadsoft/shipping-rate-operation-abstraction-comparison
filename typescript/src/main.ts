import { createCarrierXApiClient } from "./driver/carrier_x_api_client_driver.ts";
import { createCarrierYApiClient } from "./driver/carrier_y_api_client_driver.ts";
import { createCarrierZApiClient } from "./driver/carrier_z_api_client_driver.ts";
import { createUserApiClient } from "./driver/user_api_client_driver.ts";
import type { ShippingRate } from "./domain/shipping_rate.ts";
import { createPostalCodePort } from "./gateway/postal_code_gateway.ts";
import { createShippingRatePort, type Dependencies } from "./gateway/shipping_rates_gateway.ts";
import { getCheapestShippingRate } from "./usecase/get_cheapest_shipping_rate.ts";
import { ShippingDestinationNotFound } from "./usecase/get_cheapest_shipping_rate_error.ts";

const getEnv = (name: string, defaultValue: string): string => Deno.env.get(name) ?? defaultValue;

const main = async (): Promise<void> => {
  const dependencies: Dependencies = {
    carrierXApiClient: createCarrierXApiClient({
      baseUrl: getEnv("CARRIER_X_API_BASE_URL", "http://localhost:8082"),
    }),
    carrierYApiClient: createCarrierYApiClient({
      baseUrl: getEnv("CARRIER_Y_API_BASE_URL", "http://localhost:8083"),
    }),
    carrierZApiClient: createCarrierZApiClient({
      baseUrl: getEnv("CARRIER_Z_API_BASE_URL", "http://localhost:8084"),
    }),
  };
  const postalCodePort = createPostalCodePort({
    userApiClient: createUserApiClient({
      baseUrl: getEnv("USER_API_BASE_URL", "http://localhost:8081"),
    }),
  });
  const shippingRatePort = createShippingRatePort(dependencies);
  const result = await getCheapestShippingRate({
    postalCodePort,
    shippingRatePort,
  })({ userId: "user-123", weight: 1000 });

  if (result.type === "error") {
    console.error(
      result.error === ShippingDestinationNotFound
        ? "配送先が登録されていません。"
        : "一番安い送料の取得に失敗しました。",
    );
    return;
  }

  printShippingRate(result.value);
};

const printShippingRate = (rate: ShippingRate): void => {
  console.log("一番安い送料の取得に成功しました。");
  console.log(`  ${rate.carrier}: ${rate.amount}円`);
};

if (import.meta.main) {
  await main();
}
