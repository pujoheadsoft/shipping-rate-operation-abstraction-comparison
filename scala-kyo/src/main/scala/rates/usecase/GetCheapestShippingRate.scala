package rates.usecase

import kyo.*
import rates.domain.*

enum GetCheapestShippingRateError:
  case ShippingDestinationNotFound
  case GetCheapestShippingRateFailed

object GetCheapestShippingRate:
  def apply(userId: UserId, weight: Weight)(using
      Frame
  ): ShippingRate < (PostalCodePort & ShippingRatePort & Abort[GetCheapestShippingRateError]) =
    PostalCodePort.fetch(userId).map {
      case Left(FetchPostalCodeError.PostalCodeNotFound) =>
        Abort.fail(GetCheapestShippingRateError.ShippingDestinationNotFound)
      case Left(FetchPostalCodeError.FetchPostalCodeFailed) =>
        Abort.fail(GetCheapestShippingRateError.GetCheapestShippingRateFailed)
      case Right(postalCode) =>
        ShippingRatePort.fetch(Shipment(postalCode.value, weight.value)).map {
          case Right(rates) => rates.findCheapest
          case Left(_)      => Abort.fail(GetCheapestShippingRateError.GetCheapestShippingRateFailed)
        }
    }
