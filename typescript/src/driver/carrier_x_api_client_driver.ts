import { fetchPost } from "./http_client.ts";
import type { CarrierXApiClient, CarrierXRateRequest, CarrierXRateResponse } from "../gateway/carrier_x_api_client.ts";

export type CarrierXApiEnvironment = Readonly<{
  baseUrl: string;
}>;

export const createCarrierXApiClient = (
  environment: CarrierXApiEnvironment,
): CarrierXApiClient => ({
  fetchRate: (request: CarrierXRateRequest) => performFetchRate(environment, request),
});

const performFetchRate = async (
  environment: CarrierXApiEnvironment,
  request: CarrierXRateRequest,
): Promise<CarrierXRateResponse> => {
  const body = await fetchPost(
    `${environment.baseUrl}/shipping-rates`,
    JSON.stringify(request),
  );
  return JSON.parse(body) as CarrierXRateResponse;
};
