import { fetchPost } from "./http_client.ts";
import type { CarrierYApiClient, CarrierYRateRequest, CarrierYRateResponse } from "../gateway/carrier_y_api_client.ts";

export type CarrierYApiEnvironment = Readonly<{
  baseUrl: string;
}>;

export const createCarrierYApiClient = (
  environment: CarrierYApiEnvironment,
): CarrierYApiClient => ({
  fetchRate: (request: CarrierYRateRequest) => performFetchRate(environment, request),
});

const performFetchRate = async (
  environment: CarrierYApiEnvironment,
  request: CarrierYRateRequest,
): Promise<CarrierYRateResponse> => {
  const body = await fetchPost(
    `${environment.baseUrl}/rates/quote`,
    JSON.stringify(request),
  );
  return JSON.parse(body) as CarrierYRateResponse;
};
