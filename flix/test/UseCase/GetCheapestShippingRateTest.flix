use UseCase.ShippingRatePort
use UseCase.PostalCodePort
use UseCase.PostalCodePort.FetchPostalCodeError
use UseCase.ShippingRatePort.FetchShippingRatesError
use UseCase.GetCheapestShippingRate.GetCheapestShippingRateError
use Domain.ShippingRate.ShippingRate
use Domain.ShippingRates.ShippingRates
use Domain.PostalCode
use Domain.UserId.UserId
use Domain.Weight.Weight
use UseCase.GetCheapestShippingRate.getCheapestShippingRate

@Test
def testGetCheapestShippingRateSuccess(): Unit \ Assert =
    let userId = UserId("U1");
    let weight = Weight(100);
    let shippingRates = ShippingRates(
        ShippingRate({ carrier = "配送業者X", amount = 300 }),
        ShippingRate({ carrier = "配送業者Y", amount = 200 }) :: Nil
    );
    let actual = run {
        getCheapestShippingRate(userId, weight)
    } with handler PostalCodePort {
        def fetchPostalCodeByUserId(_id, k) = k(Ok(PostalCode("111-1111")))
    } with handler ShippingRatePort {
        def fetchShippingRates(_shipment, k) = k(Ok(shippingRates))
    };
    Assert.assertEq(
        expected = Ok(ShippingRate({ carrier = "配送業者Y", amount = 200 })),
        actual
    )

@Test
def testGetCheapestShippingRatePostalCodeFailure(): Unit \ Assert =
    let actual = run {
        getCheapestShippingRate(UserId("U1"), Weight(100))
    } with handler PostalCodePort {
        def fetchPostalCodeByUserId(_id, k) = k(Err(FetchPostalCodeError.FetchPostalCodeFailed))
    } with handler ShippingRatePort {
        def fetchShippingRates(_shipment, k) = {
            Assert.fail("ShippingRatePort must not be called after postal-code failure");
            k(Err(FetchShippingRatesError.FetchShippingRatesFailed))
        }
    };
    Assert.assertEq(expected = Err(GetCheapestShippingRateError.GetCheapestShippingRateFailed), actual)

@Test
def testGetCheapestShippingRatePostalCodeNotFound(): Unit \ Assert =
    let actual = run {
        getCheapestShippingRate(UserId("unknown"), Weight(100))
    } with handler PostalCodePort {
        def fetchPostalCodeByUserId(_id, k) = k(Err(FetchPostalCodeError.PostalCodeNotFound))
    } with handler ShippingRatePort {
        def fetchShippingRates(_shipment, k) = {
            Assert.fail("ShippingRatePort must not be called when postal code is absent");
            k(Err(FetchShippingRatesError.FetchShippingRatesFailed))
        }
    };
    Assert.assertEq(expected = Err(GetCheapestShippingRateError.ShippingDestinationNotFound), actual)

@Test
def testGetCheapestShippingRateShippingRatesFailure(): Unit \ Assert =
    let actual = run {
        getCheapestShippingRate(UserId("U1"), Weight(100))
    } with handler PostalCodePort {
        def fetchPostalCodeByUserId(_id, k) = k(Ok(PostalCode("111-1111")))
    } with handler ShippingRatePort {
        def fetchShippingRates(_shipment, k) = k(Err(FetchShippingRatesError.FetchShippingRatesFailed))
    };
    Assert.assertEq(expected = Err(GetCheapestShippingRateError.GetCheapestShippingRateFailed), actual)
