import { fetchPost } from "./http_client.ts";
import type { CarrierZApiClient, CarrierZRateRequest, CarrierZRateResponse } from "../gateway/carrier_z_api_client.ts";

export type CarrierZApiEnvironment = Readonly<{
  baseUrl: string;
}>;

export const createCarrierZApiClient = (
  environment: CarrierZApiEnvironment,
): CarrierZApiClient => ({
  fetchRate: (request: CarrierZRateRequest) => performFetchRate(environment, request),
});

const performFetchRate = async (
  environment: CarrierZApiEnvironment,
  request: CarrierZRateRequest,
): Promise<CarrierZRateResponse> => {
  const body = await fetchPost(
    `${environment.baseUrl}/shipping/quote`,
    JSON.stringify(request),
  );
  return JSON.parse(body) as CarrierZRateResponse;
};
