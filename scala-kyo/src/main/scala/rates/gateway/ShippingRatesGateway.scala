package rates.gateway

import kyo.*
import kyo.kernel.*
import rates.domain.*
import rates.usecase.*

object ShippingRatesGateway:
  def run[A, S](
      program: A < (ShippingRatePort & S)
  )(using Frame): A < (CarrierXApiClient & CarrierYApiClient & CarrierZApiClient & Async & S) =
    ArrowEffect.handleLoop(Tag[ShippingRatePort], program)([C] =>
      operation =>
        operation match
          case ShippingRatePort.Op.Fetch(shipment) =>
            fetchResult(shipment).map(value => Loop.continue(value))
    )

  def fetch(shipment: Shipment)(using
      Frame
  ): ShippingRates <
    (CarrierXApiClient & CarrierYApiClient & CarrierZApiClient & Async & Abort[FetchShippingRatesError]) = Async
    .zip(fetchCarrierXRate(shipment), fetchCarrierYRate(shipment), fetchCarrierZRate(shipment))
    .map((x, y, z) => ShippingRates(x, List(y, z)))

  private def fetchCarrierXRate(
      shipment: Shipment
  )(using Frame): ShippingRate < (CarrierXApiClient & Async & Abort[FetchShippingRatesError]) = CarrierXApiClient
    .fetch(CarrierXRateRequest(shipment.destinationPostalCode, shipment.weight))
    .map(fromApi)
    .map(response => ShippingRate("CarrierX", response.amount))

  private def fetchCarrierYRate(
      shipment: Shipment
  )(using Frame): ShippingRate < (CarrierYApiClient & Async & Abort[FetchShippingRatesError]) = CarrierYApiClient
    .fetch(CarrierYRateRequest(shipment.destinationPostalCode, shipment.weight))
    .map(fromApi)
    .map(response => ShippingRate("CarrierY", response.price))

  private def fetchCarrierZRate(
      shipment: Shipment
  )(using Frame): ShippingRate < (CarrierZApiClient & Async & Abort[FetchShippingRatesError]) = CarrierZApiClient
    .fetch(CarrierZRateRequest(shipment.destinationPostalCode, shipment.weight))
    .map(fromApi)
    .map(response => ShippingRate("CarrierZ", response.amount))

  private def fetchResult(
      shipment: Shipment
  )(using Frame): FetchShippingRatesResult < (CarrierXApiClient & CarrierYApiClient & CarrierZApiClient & Async) = Abort
    .run[FetchShippingRatesError](fetch(shipment))
    .map {
      case Result.Success(rates) =>
        Right(rates)
      case Result.Failure(error) =>
        Left(error)
      case Result.Panic(error) =>
        throw error
    }

  private def fromApi[A, E](value: Either[E, A])(using Frame): A < Abort[FetchShippingRatesError] =
    value match
      case Right(result) =>
        result
      case Left(_) =>
        Abort.fail(FetchShippingRatesError.FetchShippingRatesFailed)
