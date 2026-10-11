import { Context, Effect, Layer } from "effect";
import type { Shipment } from "../domain/shipment.ts";
import type { ShippingRate } from "../domain/shipping_rate.ts";
import type { ShippingRates } from "../domain/shipping_rates.ts";
import { FetchShippingRatesFailed, ShippingRatePort } from "../usecase/shipping_rate_port.ts";
import { CarrierXApiClient, type CarrierXRateRequest, type CarrierXRateResponse } from "./carrier_x_api_client.ts";
import { CarrierYApiClient, type CarrierYRateRequest, type CarrierYRateResponse } from "./carrier_y_api_client.ts";
import { CarrierZApiClient, type CarrierZRateRequest, type CarrierZRateResponse } from "./carrier_z_api_client.ts";

export const ShippingRatesGatewayLive: Layer.Layer<
  ShippingRatePort,
  never,
  CarrierXApiClient | CarrierYApiClient | CarrierZApiClient
> = Layer.effect(
  ShippingRatePort,
  Effect.gen(function* () {
    const carrierX = yield* CarrierXApiClient;
    const carrierY = yield* CarrierYApiClient;
    const carrierZ = yield* CarrierZApiClient;

    return {
      fetchShippingRates: (shipment: Shipment): Effect.Effect<ShippingRates, FetchShippingRatesFailed, never> =>
        fetchShippingRates(shipment).pipe(
          Effect.provideService(CarrierXApiClient, carrierX),
          Effect.provideService(CarrierYApiClient, carrierY),
          Effect.provideService(CarrierZApiClient, carrierZ),
        ),
    } satisfies Context.Service.Shape<typeof ShippingRatePort>;
  }),
);

const fetchShippingRates = (
  shipment: Shipment,
): Effect.Effect<ShippingRates, FetchShippingRatesFailed, CarrierXApiClient | CarrierYApiClient | CarrierZApiClient> =>
  Effect.all([fetchCarrierXRate(shipment), fetchCarrierYRate(shipment), fetchCarrierZRate(shipment)] as const, {
    concurrency: "unbounded",
  });

const fetchCarrierXRate = (
  shipment: Shipment,
): Effect.Effect<ShippingRate, FetchShippingRatesFailed, CarrierXApiClient> =>
  CarrierXApiClient.use((carrierX) =>
    carrierX.fetchRate(toCarrierXRateRequest(shipment)).pipe(Effect.map(carrierXResponseToShippingRate)),
  ).pipe(Effect.mapError(() => new FetchShippingRatesFailed()));

const fetchCarrierYRate = (
  shipment: Shipment,
): Effect.Effect<ShippingRate, FetchShippingRatesFailed, CarrierYApiClient> =>
  CarrierYApiClient.use((carrierY) =>
    carrierY.fetchRate(toCarrierYRateRequest(shipment)).pipe(Effect.map(carrierYResponseToShippingRate)),
  ).pipe(Effect.mapError(() => new FetchShippingRatesFailed()));

const fetchCarrierZRate = (
  shipment: Shipment,
): Effect.Effect<ShippingRate, FetchShippingRatesFailed, CarrierZApiClient> =>
  CarrierZApiClient.use((carrierZ) =>
    carrierZ.fetchRate(toCarrierZRateRequest(shipment)).pipe(Effect.map(carrierZResponseToShippingRate)),
  ).pipe(Effect.mapError(() => new FetchShippingRatesFailed()));

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

const carrierXResponseToShippingRate = (response: CarrierXRateResponse): ShippingRate => ({
  carrier: "CarrierX",
  amount: response.amount,
});

const carrierYResponseToShippingRate = (response: CarrierYRateResponse): ShippingRate => ({
  carrier: "CarrierY",
  amount: response.price,
});

const carrierZResponseToShippingRate = (response: CarrierZRateResponse): ShippingRate => ({
  carrier: "CarrierZ",
  amount: response.amount,
});
