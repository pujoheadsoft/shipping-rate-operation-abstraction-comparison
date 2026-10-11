package rates.gateway

import kyo.*
import kyo.kernel.*

final case class CarrierZRateRequest(postalCode: String, weight: Int)
final case class CarrierZRateResponse(amount: Int, serviceCode: String)
enum CarrierZApiError:
  case CarrierZApiOperationFailed

sealed trait CarrierZApiClient extends ContextEffect[CarrierZApiClient.Client]

object CarrierZApiClient:
  trait Client:
    def fetch(request: CarrierZRateRequest)(using Frame): Either[CarrierZApiError, CarrierZRateResponse] < Async

  private[rates] given Tag[CarrierZApiClient] = Tag.derive

  def fetch(
      request: CarrierZRateRequest
  )(using Frame): Either[CarrierZApiError, CarrierZRateResponse] < (CarrierZApiClient & Async) =
    ContextEffect.suspendWith(Tag[CarrierZApiClient])(_.fetch(request))
