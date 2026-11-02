use Domain.ShippingRates.findCheapest
use Domain.ShippingRates.ShippingRates
use Domain.ShippingRate.ShippingRate

@Test
def testFindCheapest(): Unit \ Assert =
    let rates = ShippingRates(
        ShippingRate({ carrier = "X", amount = 50 }),
        ShippingRate({ carrier = "Y", amount = 30 }) ::
            ShippingRate({ carrier = "Z", amount = 40 }) :: Nil);
    let actual = findCheapest(rates);

    Assert.assertEq(expected = ShippingRate({ carrier = "Y", amount = 30 }), actual)

@Test
def testFindFirstCheapest(): Unit \ Assert =
    let rates = ShippingRates(
        ShippingRate({ carrier = "X", amount = 50 }),
        ShippingRate({ carrier = "Y", amount = 30 }) ::
            ShippingRate({ carrier = "Z", amount = 30 }) :: Nil);
    let actual = findCheapest(rates);

    Assert.assertEq(expected = ShippingRate({ carrier = "Y", amount = 30 }), actual)
