package rates.usecase

import kyo.*
import rates.domain.*

enum GetShippingRatesError:
  case GetShippingRatesFailed

object GetShippingRates:
  def apply(shipment: Shipment)(using Frame): ShippingRates < (ShippingRatePort & Abort[GetShippingRatesError]) =
    ShippingRatePort
      .fetch(shipment)
      .map {
        case Right(rates) =>
          rates
        case Left(_) =>
          Abort.fail(GetShippingRatesError.GetShippingRatesFailed)
      }
