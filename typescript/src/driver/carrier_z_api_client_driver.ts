import { fetchPost } from "./http_client.ts";
import type { CarrierZApiClient, CarrierZRateRequest, CarrierZRateResponse } from "../gateway/carrier_z_api_client.ts";

export type CarrierZApiEnvironment = Readonly<{
  baseUrl: string;
}>;

export const createCarrierZApiClient = (
  environment: CarrierZApiEnvironment,
): CarrierZApiClient => ({
  fetchRate: async (request: CarrierZRateRequest) => {
    const body = await fetchPost(
      `${environment.baseUrl}/shipping/quote`,
      JSON.stringify(request),
    );
    return JSON.parse(body) as CarrierZRateResponse;
  },
});
