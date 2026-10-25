use Domain.PostalCode
use Domain.Weight
use Domain.Shipment
use Domain.ShippingRate
use Domain.ShippingRates
use UseCase.GetShippingRates.{GetShippingRatesError, getShippingRates}
use UseCase.ShippingRatePort.{FetchShippingRatesError, handleWith}

@Test
def useCaseSuccessTest(): Unit \ Assert =
    let shipment = Shipment(PostalCode("111-1111"), Weight(10));
    let rates = ShippingRates(ShippingRate("Carrier X", 100), Nil);
    let port = received -> match received {
        case Shipment(PostalCode("111-1111"), Weight(10)) => Ok(rates)
        case _ => Err(FetchShippingRatesError.FetchShippingRatesFailed)
    };
    Assert.assertEq(
        expected = Ok(rates),
        handleWith(() -> getShippingRates(shipment), port)
    )

@Test
def useCaseFailureTest(): Unit \ Assert =
    let shipment = Shipment(PostalCode("111-1111"), Weight(10));
    let port = received -> match received {
        case Shipment(PostalCode("111-1111"), Weight(10)) =>
            Err(FetchShippingRatesError.FetchShippingRatesFailed)
        case _ => Ok(ShippingRates(ShippingRate("unexpected", 0), Nil))
    };
    Assert.assertEq(
        expected = Err(GetShippingRatesError.GetShippingRatesFailed),
        handleWith(() -> getShippingRates(shipment), port)
    )
