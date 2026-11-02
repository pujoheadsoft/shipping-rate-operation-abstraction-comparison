import java.lang.System

use Domain.PostalCode
use Domain.Weight
use Domain.Shipment
use Domain.ShippingRate
use Domain.ShippingRates
use Gateway.CarrierXApiClient.{CarrierXApiClient, CarrierXApiError, CarrierXRateRequest, CarrierXRateResponse}
use Gateway.CarrierYApiClient.{CarrierYApiClient, CarrierYApiError, CarrierYRateRequest, CarrierYRateResponse}
use Gateway.CarrierZApiClient.{CarrierZApiClient, CarrierZApiError, CarrierZRateRequest, CarrierZRateResponse}
use Gateway.ShippingRatesGateway.{fetchShippingRatesConcurrently, fetchX, fetchY, fetchZ}
use UseCase.ShippingRatePort.FetchShippingRatesError

def gatewayTestIo(): Unit \ IO =
    let _ = System.currentTimeMillis(); ()

def runTestX(
    clientHandler: CarrierXRateRequest -> Result[CarrierXApiError, CarrierXRateResponse] \ IO,
    action: Unit -> a \ CarrierXApiClient
): a \ IO = run { action() } with handler CarrierXApiClient {
    def fetchRate(request, resume) = resume(clientHandler(request))
}

def runTestY(
    clientHandler: CarrierYRateRequest -> Result[CarrierYApiError, CarrierYRateResponse] \ IO,
    action: Unit -> a \ CarrierYApiClient
): a \ IO = run { action() } with handler CarrierYApiClient {
    def fetchRate(request, resume) = resume(clientHandler(request))
}

def runTestZ(
    clientHandler: CarrierZRateRequest -> Result[CarrierZApiError, CarrierZRateResponse] \ IO,
    action: Unit -> a \ CarrierZApiClient
): a \ IO = run { action() } with handler CarrierZApiClient {
    def fetchRate(request, resume) = resume(clientHandler(request))
}

@Test
def gatewaySuccessTest(): Unit \ {Assert, Chan, NonDet, IO} =
    let x = request -> {
        gatewayTestIo();
        match request {
            case CarrierXRateRequest.CarrierXRateRequest({ destination = "111-1111", weightGrams = 1000 }) =>
                Ok(CarrierXRateResponse.CarrierXRateResponse({ amount = 1000, serviceCode = "EXPRESS" }))
            case _ => Err(CarrierXApiError.CarrierXApiOperationFailed)
        }
    };

    let y = request -> {
        gatewayTestIo();
        match request {
            case CarrierYRateRequest.CarrierYRateRequest({ postalCode = "111-1111", weight = 1000 }) =>
                Ok(CarrierYRateResponse.CarrierYRateResponse({
                    price = 2000,
                    serviceName = "Standard Delivery"
                }))
            case _ => Err(CarrierYApiError.CarrierYApiOperationFailed)
        }
    };

    let z = request -> {
        gatewayTestIo();
        match request {
            case CarrierZRateRequest.CarrierZRateRequest({ postalCode = "111-1111", weight = 1000 }) =>
                Ok(CarrierZRateResponse.CarrierZRateResponse({ amount = 3000, serviceCode = "ECONOMY" }))
            case _ => Err(CarrierZApiError.CarrierZApiOperationFailed)
        }
    };

    let expected = ShippingRates(
        ShippingRate({ carrier = "CarrierX", amount = 1000 }),
        ShippingRate({ carrier = "CarrierY", amount = 2000 }) ::
            ShippingRate({ carrier = "CarrierZ", amount = 3000 }) :: Nil
    );
    let shipment = Shipment({
        destinationPostalCode = PostalCode("111-1111"),
        weight = Weight(1000)
    });

    Assert.assertEq(
        expected = Ok(expected),
        fetchShippingRatesConcurrently(
            () -> runTestX(x, () -> fetchX(shipment)),
            () -> runTestY(y, () -> fetchY(shipment)),
            () -> runTestZ(z, () -> fetchZ(shipment))
        )
    )

@Test
def gatewayFailureTest(): Unit \ {Assert, Chan, NonDet, IO} =
    let x = request -> {
        gatewayTestIo();
        match request {
            case CarrierXRateRequest.CarrierXRateRequest({ destination = "111-1111", weightGrams = 1000 }) =>
                Ok(CarrierXRateResponse.CarrierXRateResponse({ amount = 1000, serviceCode = "EXPRESS" }))
            case _ => Err(CarrierXApiError.CarrierXApiOperationFailed)
        }
    };

    let y = request -> {
        gatewayTestIo();
        match request {
            case CarrierYRateRequest.CarrierYRateRequest({ postalCode = "111-1111", weight = 1000 }) =>
                Err(CarrierYApiError.CarrierYApiOperationFailed)
            case _ => Ok(CarrierYRateResponse.CarrierYRateResponse({
                price = 0,
                serviceName = "unexpected"
            }))
        }
    };

    let z = request -> {
        gatewayTestIo();
        match request {
            case CarrierZRateRequest.CarrierZRateRequest({ postalCode = "111-1111", weight = 1000 }) =>
                Ok(CarrierZRateResponse.CarrierZRateResponse({ amount = 3000, serviceCode = "ECONOMY" }))
            case _ => Err(CarrierZApiError.CarrierZApiOperationFailed)
        }
    };

    let shipment = Shipment({
        destinationPostalCode = PostalCode("111-1111"),
        weight = Weight(1000)
    });

    Assert.assertEq(
        expected = Err(FetchShippingRatesError.FetchShippingRatesFailed),
        fetchShippingRatesConcurrently(
            () -> runTestX(x, () -> fetchX(shipment)),
            () -> runTestY(y, () -> fetchY(shipment)),
            () -> runTestZ(z, () -> fetchZ(shipment))
        )
    )
