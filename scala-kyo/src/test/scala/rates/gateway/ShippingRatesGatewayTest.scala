package rates.gateway

import kyo.*
import kyo.AllowUnsafe.embrace.danger
import kyo.kernel.*
import org.scalamock.stubs.Stubs
import rates.domain.*
import rates.usecase.FetchShippingRatesError

class ShippingRatesGatewayTest extends munit.FunSuite, Stubs:
  private trait XClient:
    def fetchRate(request: CarrierXRateRequest): Either[CarrierXApiError, CarrierXRateResponse] < Async

  private trait YClient:
    def fetchRate(request: CarrierYRateRequest): Either[CarrierYApiError, CarrierYRateResponse] < Async

  private trait ZClient:
    def fetchRate(request: CarrierZRateRequest): Either[CarrierZApiError, CarrierZRateResponse] < Async

  private val shipment = Shipment("111-1111", 1000)

  test("3社へリクエストを送り、すべての送料を取得できる") {
    val x = stub[XClient]
    val y = stub[YClient]
    val z = stub[ZClient]

    x.fetchRate
      .returns {
        case CarrierXRateRequest("111-1111", 1000) =>
          Right(CarrierXRateResponse(1000, "EXPRESS"))
        case request =>
          fail(s"unexpected request: $request")
      }
    y.fetchRate
      .returns {
        case CarrierYRateRequest("111-1111", 1000) =>
          Right(CarrierYRateResponse(2000, "Standard Delivery"))
        case request =>
          fail(s"unexpected request: $request")
      }
    z.fetchRate
      .returns {
        case CarrierZRateRequest("111-1111", 1000) =>
          Right(CarrierZRateResponse(3000, "ECONOMY"))
        case request =>
          fail(s"unexpected request: $request")
      }

    val actual = run(x.fetchRate, y.fetchRate, z.fetchRate)
    val expected = ShippingRates(
      ShippingRate("CarrierX", 1000),
      List(ShippingRate("CarrierY", 2000), ShippingRate("CarrierZ", 3000))
    )

    assertEquals(actual, Result.Success(Result.Success(expected)))
  }

  test("Carrierでエラーが発生した場合は送料取得エラーを返す") {
    val x = stub[XClient]
    val y = stub[YClient]
    val z = stub[ZClient]

    x.fetchRate
      .returns {
        case CarrierXRateRequest("111-1111", 1000) =>
          Right(CarrierXRateResponse(1000, "EXPRESS"))
        case request =>
          fail(s"unexpected request: $request")
      }
    y.fetchRate
      .returns {
        case CarrierYRateRequest("111-1111", 1000) =>
          Left(CarrierYApiError.CarrierYApiOperationFailed)
        case request =>
          fail(s"unexpected request: $request")
      }
    z.fetchRate
      .returns {
        case CarrierZRateRequest("111-1111", 1000) =>
          Right(CarrierZRateResponse(3000, "ECONOMY"))
        case request =>
          fail(s"unexpected request: $request")
      }

    val actual = run(x.fetchRate, y.fetchRate, z.fetchRate)

    assertEquals(actual, Result.Success(Result.Failure(FetchShippingRatesError.FetchShippingRatesFailed)))
  }

  private def run(
      x: CarrierXRateRequest => Either[CarrierXApiError, CarrierXRateResponse] < Async,
      y: CarrierYRateRequest => Either[CarrierYApiError, CarrierYRateResponse] < Async,
      z: CarrierZRateRequest => Either[CarrierZApiError, CarrierZRateResponse] < Async
  ) =
    val handled = ShippingRatesGateway
      .fetch(shipment)
      .handle(runCarrierXApiClientWith(x)(_), runCarrierYApiClientWith(y)(_), runCarrierZApiClientWith(z)(_))

    KyoApp.Unsafe.runAndBlock(Duration.Infinity)(Scope.run(Abort.run[FetchShippingRatesError](handled)))

  private def runCarrierXApiClientWith[A, S](
      client: CarrierXRateRequest => Either[CarrierXApiError, CarrierXRateResponse] < Async
  )(program: A < (CarrierXApiClient & S))(using Frame): A < (Async & S) =
    val service =
      new CarrierXApiClient.Client:
        def fetch(request: CarrierXRateRequest)(using Frame) = client(request)
    ContextEffect.handleInheritable(Tag[CarrierXApiClient], service)(program)

  private def runCarrierYApiClientWith[A, S](
      client: CarrierYRateRequest => Either[CarrierYApiError, CarrierYRateResponse] < Async
  )(program: A < (CarrierYApiClient & S))(using Frame): A < (Async & S) =
    val service =
      new CarrierYApiClient.Client:
        def fetch(request: CarrierYRateRequest)(using Frame) = client(request)
    ContextEffect.handleInheritable(Tag[CarrierYApiClient], service)(program)

  private def runCarrierZApiClientWith[A, S](
      client: CarrierZRateRequest => Either[CarrierZApiError, CarrierZRateResponse] < Async
  )(program: A < (CarrierZApiClient & S))(using Frame): A < (Async & S) =
    val service =
      new CarrierZApiClient.Client:
        def fetch(request: CarrierZRateRequest)(using Frame) = client(request)
    ContextEffect.handleInheritable(Tag[CarrierZApiClient], service)(program)
