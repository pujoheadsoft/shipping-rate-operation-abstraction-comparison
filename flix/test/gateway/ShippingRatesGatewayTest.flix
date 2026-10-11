import java.lang.System

def gatewayTestIo(): Unit \ IO =
    let _ = System.currentTimeMillis(); ()

@Test
def gatewaySuccessTest(): Unit \ {Assert, Chan, NonDet, IO} =
    let x = request -> {
        gatewayTestIo();
        match request {
            case CarrierXRateRequest.CarrierXRateRequest("111-1111", 1000) =>
                Ok(CarrierXRateResponse.CarrierXRateResponse(1000, "EXPRESS"))
            case _ => Err(CarrierXApiError.CarrierXApiOperationFailed)
        }
    };

    let y = request -> {
        gatewayTestIo();
        match request {
            case CarrierYRateRequest.CarrierYRateRequest("111-1111", 1000) =>
                Ok(CarrierYRateResponse.CarrierYRateResponse(2000, "Standard Delivery"))
            case _ => Err(CarrierYApiError.CarrierYApiOperationFailed)
        }
    };

    let z = request -> {
        gatewayTestIo();
        match request {
            case CarrierZRateRequest.CarrierZRateRequest("111-1111", 1000) =>
                Ok(CarrierZRateResponse.CarrierZRateResponse(3000, "ECONOMY"))
            case _ => Err(CarrierZApiError.CarrierZApiOperationFailed)
        }
    };

    let expected = ShippingRates.ShippingRates(
        ShippingRate.ShippingRate("CarrierX", 1000),
        ShippingRate.ShippingRate("CarrierY", 2000) ::
            ShippingRate.ShippingRate("CarrierZ", 3000) :: Nil
    );

    Assert.assertEq(
        expected = Ok(expected),
        fetchShippingRates(Shipment.Shipment("111-1111", 1000), x, y, z)
    )

@Test
def gatewayFailureTest(): Unit \ {Assert, Chan, NonDet, IO} =
    let x = request -> {
        gatewayTestIo();
        match request {
            case CarrierXRateRequest.CarrierXRateRequest("111-1111", 1000) =>
                Ok(CarrierXRateResponse.CarrierXRateResponse(1000, "EXPRESS"))
            case _ => Err(CarrierXApiError.CarrierXApiOperationFailed)
        }
    };

    let y = request -> {
        gatewayTestIo();
        match request {
            case CarrierYRateRequest.CarrierYRateRequest("111-1111", 1000) =>
                Err(CarrierYApiError.CarrierYApiOperationFailed)
            case _ => Ok(CarrierYRateResponse.CarrierYRateResponse(0, "unexpected"))
        }
    };

    let z = request -> {
        gatewayTestIo();
        match request {
            case CarrierZRateRequest.CarrierZRateRequest("111-1111", 1000) =>
                Ok(CarrierZRateResponse.CarrierZRateResponse(3000, "ECONOMY"))
            case _ => Err(CarrierZApiError.CarrierZApiOperationFailed)
        }
    };

    Assert.assertEq(
        expected = Err(FetchShippingRatesError.FetchShippingRatesFailed),
        fetchShippingRates(Shipment.Shipment("111-1111", 1000), x, y, z)
    )
