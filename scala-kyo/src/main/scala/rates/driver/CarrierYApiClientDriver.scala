package rates.driver

import kyo.*
import kyo.kernel.*
import rates.gateway.*
import scala.util.control.NonFatal

final case class CarrierYApiEnvironment(baseUrl: String)

object CarrierYApiClientDriver:
  def run[A, S](environment: CarrierYApiEnvironment)(program: A < (CarrierYApiClient & S))(using
      Frame
  ): A < (Async & S) = ContextEffect.handleInheritable(Tag[CarrierYApiClient], create(environment))(program)

  private def create(environment: CarrierYApiEnvironment): CarrierYApiClient.Client =
    new CarrierYApiClient.Client:
      def fetch(request: CarrierYRateRequest)(using Frame): Either[CarrierYApiError, CarrierYRateResponse] < Async =
        Abort
          .run[DriverError](Env.run(environment)(performFetchRate(request)))
          .map {
            case Result.Success(response) =>
              Right(response)
            case Result.Failure(_) =>
              Left(CarrierYApiError.CarrierYApiOperationFailed)
            case Result.Panic(error) =>
              throw error
          }

  private def performFetchRate(
      request: CarrierYRateRequest
  )(using Frame): CarrierYRateResponse < (Env[CarrierYApiEnvironment] & Abort[DriverError] & Async) = Env
    .get[CarrierYApiEnvironment]
    .map { environment =>
      val body = ujson.Obj("postalCode" -> request.postalCode, "weight" -> request.weight).render()
      rates.driver.HttpClient.post(s"${environment.baseUrl}/rates/quote", body).map(Abort.get).map(decode)
    }

  private def decode(body: String)(using Frame): CarrierYRateResponse < Abort[DriverError] =
    try
      val json = ujson.read(body)
      CarrierYRateResponse(json("price").num.toInt, json("serviceName").str)
    catch
      case NonFatal(_) =>
        Abort.fail(DriverError.DriverOperationFailed)
