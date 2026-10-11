@Test
def useCaseSuccessTest(): Unit \ Assert =
    let shipment = Shipment.Shipment("111-1111", 10);
    let rates = ShippingRates.ShippingRates(
        ShippingRate.ShippingRate("Carrier X", 100),
        Nil
    );
    let port = received -> match received {
        case Shipment.Shipment("111-1111", 10) => Ok(rates)
        case _ => Err(FetchShippingRatesError.FetchShippingRatesFailed)
    };
    Assert.assertEq(
        expected = Ok(rates),
        handleShippingRatePortWith(() -> getShippingRates(shipment), port)
    )

@Test
def useCaseFailureTest(): Unit \ Assert =
    let shipment = Shipment.Shipment("111-1111", 10);
    let port = received -> match received {
        case Shipment.Shipment("111-1111", 10) =>
            Err(FetchShippingRatesError.FetchShippingRatesFailed)
        case _ => Ok(ShippingRates.ShippingRates(
            ShippingRate.ShippingRate("unexpected", 0),
            Nil
        ))
    };
    Assert.assertEq(
        expected = Err(GetShippingRatesError.GetShippingRatesFailed),
        handleShippingRatePortWith(() -> getShippingRates(shipment), port)
    )
