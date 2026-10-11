package rates.gateway

import kyo.*
import kyo.kernel.*

final case class CarrierXRateRequest(destination: String, weightGrams: Int)
final case class CarrierXRateResponse(amount: Int, serviceCode: String)
enum CarrierXApiError:
  case CarrierXApiOperationFailed

sealed trait CarrierXApiClient extends ContextEffect[CarrierXApiClient.Client]

object CarrierXApiClient:
  trait Client:
    def fetch(request: CarrierXRateRequest)(using Frame): Either[CarrierXApiError, CarrierXRateResponse] < Async

  private[rates] given Tag[CarrierXApiClient] = Tag.derive

  def fetch(
      request: CarrierXRateRequest
  )(using Frame): Either[CarrierXApiError, CarrierXRateResponse] < (CarrierXApiClient & Async) =
    ContextEffect.suspendWith(Tag[CarrierXApiClient])(_.fetch(request))
