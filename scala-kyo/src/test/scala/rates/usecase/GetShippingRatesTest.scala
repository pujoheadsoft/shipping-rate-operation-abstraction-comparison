package rates.usecase

import kyo.*
import kyo.AllowUnsafe.embrace.danger
import kyo.kernel.*
import org.scalamock.stubs.Stubs
import rates.domain.*

class GetShippingRatesTest extends munit.FunSuite, Stubs:
  private trait Port:
    def fetchShippingRates(shipment: Shipment): Either[FetchShippingRatesError, ShippingRates] < Async

  private val shipment = Shipment("111-1111", 10)

  test("荷物に対しての送料をすべて取得できる") {
    val expected = ShippingRates(ShippingRate("Carrier X", 100), Nil)
    val port = stub[Port]
    port
      .fetchShippingRates
      .returns {
        case Shipment("111-1111", 10) =>
          Right(expected)
        case received =>
          fail(s"unexpected shipment: $received")
      }

    val actual = run(port.fetchShippingRates)

    assertEquals(actual, Result.Success(Result.Success(expected)))
  }

  test("送料取得エラーが起きた場合はエラーを返す") {
    val port = stub[Port]
    port
      .fetchShippingRates
      .returns {
        case Shipment("111-1111", 10) =>
          Left(FetchShippingRatesError.FetchShippingRatesFailed)
        case received =>
          fail(s"unexpected shipment: $received")
      }

    val actual = run(port.fetchShippingRates)

    assertEquals(actual, Result.Success(Result.Failure(GetShippingRatesError.GetShippingRatesFailed)))
  }

  private def run(port: Shipment => Either[FetchShippingRatesError, ShippingRates] < Async) =
    val handled =
      ArrowEffect.handleLoop(Tag[ShippingRatePort], GetShippingRates(shipment))([C] =>
        operation =>
          operation match
            case ShippingRatePort.Op.Fetch(value) =>
              port(value).map(result => Loop.continue(result))
      )
    KyoApp.Unsafe.runAndBlock(Duration.Infinity)(Scope.run(Abort.run[GetShippingRatesError](handled)))
