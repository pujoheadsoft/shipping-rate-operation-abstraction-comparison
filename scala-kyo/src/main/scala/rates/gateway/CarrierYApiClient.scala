package rates.gateway

import kyo.*
import kyo.kernel.*

final case class CarrierYRateRequest(postalCode: String, weight: Int)
final case class CarrierYRateResponse(price: Int, serviceName: String)
enum CarrierYApiError:
  case CarrierYApiOperationFailed

sealed trait CarrierYApiClient extends ContextEffect[CarrierYApiClient.Client]

object CarrierYApiClient:
  trait Client:
    def fetch(request: CarrierYRateRequest)(using Frame): Either[CarrierYApiError, CarrierYRateResponse] < Async

  private[rates] given Tag[CarrierYApiClient] = Tag.derive

  def fetch(
      request: CarrierYRateRequest
  )(using Frame): Either[CarrierYApiError, CarrierYRateResponse] < (CarrierYApiClient & Async) =
    ContextEffect.suspendWith(Tag[CarrierYApiClient])(_.fetch(request))
