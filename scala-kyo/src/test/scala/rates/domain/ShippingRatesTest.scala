package rates.domain

class ShippingRatesTest extends munit.FunSuite:
  test("一番安い送料を返し、同額なら先頭を保つ") {
    val rates = ShippingRates(
      ShippingRate("X", 50),
      List(ShippingRate("Y", 30), ShippingRate("Z", 30))
    )
    assertEquals(rates.findCheapest, ShippingRate("Y", 30))
  }
