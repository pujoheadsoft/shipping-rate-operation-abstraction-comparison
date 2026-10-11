package rates.driver

import kyo.*
import kyo.kernel.*
import rates.gateway.*
import scala.util.control.NonFatal

final case class CarrierXApiEnvironment(baseUrl: String)

object CarrierXApiClientDriver:
  def run[A, S](environment: CarrierXApiEnvironment)(program: A < (CarrierXApiClient & S))(using
      Frame
  ): A < (Async & S) = ContextEffect.handleInheritable(Tag[CarrierXApiClient], create(environment))(program)

  private def create(environment: CarrierXApiEnvironment): CarrierXApiClient.Client =
    new CarrierXApiClient.Client:
      def fetch(request: CarrierXRateRequest)(using Frame): Either[CarrierXApiError, CarrierXRateResponse] < Async =
        Abort
          .run[DriverError](Env.run(environment)(performFetchRate(request)))
          .map {
            case Result.Success(response) =>
              Right(response)
            case Result.Failure(_) =>
              Left(CarrierXApiError.CarrierXApiOperationFailed)
            case Result.Panic(error) =>
              throw error
          }

  private def performFetchRate(
      request: CarrierXRateRequest
  )(using Frame): CarrierXRateResponse < (Env[CarrierXApiEnvironment] & Abort[DriverError] & Async) = Env
    .get[CarrierXApiEnvironment]
    .map { environment =>
      val body = ujson.Obj("destination" -> request.destination, "weightGrams" -> request.weightGrams).render()
      rates.driver.HttpClient.post(s"${environment.baseUrl}/shipping-rates", body).map(Abort.get).map(decode)
    }

  private def decode(body: String)(using Frame): CarrierXRateResponse < Abort[DriverError] =
    try
      val json = ujson.read(body)
      CarrierXRateResponse(json("amount").num.toInt, json("serviceCode").str)
    catch
      case NonFatal(_) =>
        Abort.fail(DriverError.DriverOperationFailed)
