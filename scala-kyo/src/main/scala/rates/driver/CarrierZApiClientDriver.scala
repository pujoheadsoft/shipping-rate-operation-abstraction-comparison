package rates.driver

import kyo.*
import kyo.kernel.*
import rates.gateway.*
import scala.util.control.NonFatal

final case class CarrierZApiEnvironment(baseUrl: String)

object CarrierZApiClientDriver:
  def run[A, S](environment: CarrierZApiEnvironment)(program: A < (CarrierZApiClient & S))(using
      Frame
  ): A < (Async & S) = ContextEffect.handleInheritable(Tag[CarrierZApiClient], create(environment))(program)

  private def create(environment: CarrierZApiEnvironment): CarrierZApiClient.Client =
    new CarrierZApiClient.Client:
      def fetch(request: CarrierZRateRequest)(using Frame): Either[CarrierZApiError, CarrierZRateResponse] < Async =
        Abort
          .run[DriverError](Env.run(environment)(performFetchRate(request)))
          .map {
            case Result.Success(response) =>
              Right(response)
            case Result.Failure(_) =>
              Left(CarrierZApiError.CarrierZApiOperationFailed)
            case Result.Panic(error) =>
              throw error
          }

  private def performFetchRate(
      request: CarrierZRateRequest
  )(using Frame): CarrierZRateResponse < (Env[CarrierZApiEnvironment] & Abort[DriverError] & Async) = Env
    .get[CarrierZApiEnvironment]
    .map { environment =>
      val body = ujson.Obj("postalCode" -> request.postalCode, "weight" -> request.weight).render()
      rates.driver.HttpClient.post(s"${environment.baseUrl}/shipping/quote", body).map(Abort.get).map(decode)
    }

  private def decode(body: String)(using Frame): CarrierZRateResponse < Abort[DriverError] =
    try
      val json = ujson.read(body)
      CarrierZRateResponse(json("amount").num.toInt, json("serviceCode").str)
    catch
      case NonFatal(_) =>
        Abort.fail(DriverError.DriverOperationFailed)
