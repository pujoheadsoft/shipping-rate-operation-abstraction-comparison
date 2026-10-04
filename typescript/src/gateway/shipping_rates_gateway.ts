import { error, ok, type Result } from "../data/result.ts";
import type { Shipment } from "../domain/shipment.ts";
import type { ShippingRate } from "../domain/shipping_rate.ts";
import type { ShippingRates } from "../domain/shipping_rates.ts";
import { type FetchShippingRatesError, FetchShippingRatesFailed } from "../port/shipping_rate_error.ts";
import type { ShippingRatePort } from "../port/shipping_rate_port.ts";
import type { CarrierXApiClient, CarrierXRateRequest, CarrierXRateResponse } from "./carrier_x_api_client.ts";
import type { CarrierYApiClient, CarrierYRateRequest, CarrierYRateResponse } from "./carrier_y_api_client.ts";
import type { CarrierZApiClient, CarrierZRateRequest, CarrierZRateResponse } from "./carrier_z_api_client.ts";

export type Dependencies = Readonly<{
  carrierXApiClient: CarrierXApiClient;
  carrierYApiClient: CarrierYApiClient;
  carrierZApiClient: CarrierZApiClient;
}>;

type FetchShippingRatesResult = Result<FetchShippingRatesError, ShippingRates>;

export const fetchShippingRates = (dependencies: Dependencies) => {
  return async (shipment: Shipment): Promise<FetchShippingRatesResult> => {
    try {
      const rates: ShippingRates = await Promise.all([
        fetchCarrierXRate(dependencies, shipment),
        fetchCarrierYRate(dependencies, shipment),
        fetchCarrierZRate(dependencies, shipment),
      ]);

      return ok(rates);
    } catch {
      return error(FetchShippingRatesFailed);
    }
  };
};

export const createShippingRatePort = (dependencies: Dependencies): ShippingRatePort => ({
  fetchShippingRates: fetchShippingRates(dependencies),
});

const fetchCarrierXRate = (dependencies: Dependencies, shipment: Shipment): Promise<ShippingRate> =>
  dependencies.carrierXApiClient.fetchRate(toCarrierXRateRequest(shipment))
    .then(carrierXResponseToShippingRate);

const fetchCarrierYRate = (dependencies: Dependencies, shipment: Shipment): Promise<ShippingRate> =>
  dependencies.carrierYApiClient.fetchRate(toCarrierYRateRequest(shipment))
    .then(carrierYResponseToShippingRate);

const fetchCarrierZRate = (dependencies: Dependencies, shipment: Shipment): Promise<ShippingRate> =>
  dependencies.carrierZApiClient.fetchRate(toCarrierZRateRequest(shipment))
    .then(carrierZResponseToShippingRate);

const toCarrierXRateRequest = (shipment: Shipment): CarrierXRateRequest => ({
  destination: shipment.destinationPostalCode,
  weightGrams: shipment.weight,
});

const toCarrierYRateRequest = (shipment: Shipment): CarrierYRateRequest => ({
  postalCode: shipment.destinationPostalCode,
  weight: shipment.weight,
});

const toCarrierZRateRequest = (shipment: Shipment): CarrierZRateRequest => ({
  postalCode: shipment.destinationPostalCode,
  weight: shipment.weight,
});

const carrierXResponseToShippingRate = (
  response: CarrierXRateResponse,
): ShippingRate => ({ carrier: "CarrierX", amount: response.amount });

const carrierYResponseToShippingRate = (
  response: CarrierYRateResponse,
): ShippingRate => ({ carrier: "CarrierY", amount: response.price });

const carrierZResponseToShippingRate = (
  response: CarrierZRateResponse,
): ShippingRate => ({ carrier: "CarrierZ", amount: response.amount });
