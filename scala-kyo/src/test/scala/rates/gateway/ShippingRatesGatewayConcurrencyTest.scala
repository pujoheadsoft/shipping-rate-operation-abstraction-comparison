package rates.gateway

import java.util.concurrent.{CountDownLatch, TimeUnit}
import kyo.*
import kyo.AllowUnsafe.embrace.danger
import kyo.kernel.*
import rates.domain.*
import rates.usecase.FetchShippingRatesError

class ShippingRatesGatewayConcurrencyTest extends munit.FunSuite:
  test("未解釈Carrier effectの3つのbranchが重なる") {
    val started = CountDownLatch(3)
    val release = CountDownLatch(1)

    def gate[A](value: A): A < Async = Async.defer {
      started.countDown()
      assert(release.await(5, TimeUnit.SECONDS))
      value
    }

    val program = ShippingRatesGateway.fetch(Shipment("111-1111", 1000))
    val handled = program.handle(
      runCarrierXApiClientWith(_ => gate(Right(CarrierXRateResponse(1, "EXPRESS"))))(_),
      runCarrierYApiClientWith(_ => gate(Right(CarrierYRateResponse(2, "Standard Delivery"))))(_),
      runCarrierZApiClientWith(_ => gate(Right(CarrierZRateResponse(3, "ECONOMY"))))(_)
    )
    @volatile
    var actual: Any = null
    @volatile
    var failure: Throwable | Null = null
    val runner =
      new Thread(() => {
        try
          actual = KyoApp.Unsafe.runAndBlock(Duration.Infinity)(Scope.run(Abort.run[FetchShippingRatesError](handled)))
        catch
          case error: Throwable =>
            failure = error
      })

    runner.start()
    try
      assert(started.await(5, TimeUnit.SECONDS), "3つのbranchが開始されなかった")
      release.countDown()
      runner.join(5000)

      assert(!runner.isAlive, "Gatewayが終了しなかった")
      assertEquals(failure, null)
      assertEquals(
        actual,
        Result.Success(
          Result.Success(
            ShippingRates(ShippingRate("CarrierX", 1), List(ShippingRate("CarrierY", 2), ShippingRate("CarrierZ", 3)))
          )
        )
      )
    finally
      release.countDown()
      if runner.isAlive then
        runner.interrupt()
      runner.join(5000)
  }

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
