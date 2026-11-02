package rates.usecase

import kyo.*
import kyo.AllowUnsafe.embrace.danger
import kyo.kernel.*
import rates.domain.*

class GetCheapestShippingRateTest extends munit.FunSuite:
  private val rates = ShippingRates(
    ShippingRate("X", 300),
    List(ShippingRate("Y", 200))
  )

  test("ユーザーの配送先に対する最安送料を返す") {
    val actual = run(
      _ => Right(PostalCode("111-1111")),
      _ => Right(rates)
    )
    assertEquals(actual, Result.Success(Result.Success(ShippingRate("Y", 200))))
  }

  test("郵便番号がなければ送料Portを呼ばない") {
    var shippingCalled = false
    val actual = run(
      _ => Left(FetchPostalCodeError.PostalCodeNotFound),
      _ =>
        shippingCalled = true
        Right(rates)
    )
    assertEquals(shippingCalled, false)
    assertEquals(
      actual,
      Result.Success(Result.Failure(GetCheapestShippingRateError.ShippingDestinationNotFound))
    )
  }

  private def run(
      postal: UserId => FetchPostalCodeResult,
      shipping: Shipment => FetchShippingRatesResult
  ) =
    val program = GetCheapestShippingRate(UserId("U1"), Weight(1000))
    val postalHandled = ArrowEffect.handleLoop(Tag[PostalCodePort], program)([C] =>
      operation =>
        operation match
          case PostalCodePort.Op.Fetch(userId) => Loop.continue(postal(userId))
    )
    val shippingHandled = ArrowEffect.handleLoop(Tag[ShippingRatePort], postalHandled)([C] =>
      operation =>
        operation match
          case ShippingRatePort.Op.Fetch(shipment) => Loop.continue(shipping(shipment))
    )
    KyoApp.Unsafe.runAndBlock(Duration.Infinity)(Scope.run(Abort.run[GetCheapestShippingRateError](shippingHandled)))
