pub mod Gateway.ShippingRatesGateway {
    use Domain.PostalCode
    use Domain.Weight
    use Domain.Shipment
    use Domain.ShippingRate
    use Domain.ShippingRates
    use Driver.CarrierXApiClientDriver.{CarrierXApiEnvironment, runCarrierXApiClient}
    use Driver.CarrierYApiClientDriver.{CarrierYApiEnvironment, runCarrierYApiClient}
    use Driver.CarrierZApiClientDriver.{CarrierZApiEnvironment, runCarrierZApiClient}
    use Gateway.CarrierXApiClient.{CarrierXApiClient, CarrierXApiError, CarrierXRateRequest, CarrierXRateResponse}
    use Gateway.CarrierYApiClient.{CarrierYApiClient, CarrierYApiError, CarrierYRateRequest, CarrierYRateResponse}
    use Gateway.CarrierZApiClient.{CarrierZApiClient, CarrierZApiError, CarrierZRateRequest, CarrierZRateResponse}
    use UseCase.ShippingRatePort.{FetchShippingRatesError, ShippingRatePort}

    pub def runShippingRatePort(
        xEnvironment: CarrierXApiEnvironment,
        yEnvironment: CarrierYApiEnvironment,
        zEnvironment: CarrierZApiEnvironment,
        action: Unit -> a \ ef
    ): a \ (ef - ShippingRatePort) + Chan + NonDet + IO = run {
        action()
    } with handler ShippingRatePort {
        def fetchShippingRates(shipment, resume) =
            resume(Gateway.ShippingRatesGateway.fetchShippingRates(
                shipment,
                xEnvironment,
                yEnvironment,
                zEnvironment
            ))
    }

    pub def fetchX(shipment: Shipment): Result[FetchShippingRatesError, ShippingRate] \ CarrierXApiClient =
        let Shipment({
            destinationPostalCode = PostalCode(code),
            weight = Weight(weight)
        }) = shipment;
        match CarrierXApiClient.fetchRate(CarrierXRateRequest.CarrierXRateRequest({
            destination = code,
            weightGrams = weight
        })) {
            case Ok(CarrierXRateResponse.CarrierXRateResponse({ amount = amount, serviceCode = _ })) =>
                Ok(ShippingRate({ carrier = "CarrierX", amount = amount }))
            case Err(_) => Err(FetchShippingRatesError.FetchShippingRatesFailed)
        }

    pub def fetchY(shipment: Shipment): Result[FetchShippingRatesError, ShippingRate] \ CarrierYApiClient =
        let Shipment({
            destinationPostalCode = PostalCode(code),
            weight = Weight(weight)
        }) = shipment;
        match CarrierYApiClient.fetchRate(CarrierYRateRequest.CarrierYRateRequest({
            postalCode = code,
            weight = weight
        })) {
            case Ok(CarrierYRateResponse.CarrierYRateResponse({ price = price, serviceName = _ })) =>
                Ok(ShippingRate({ carrier = "CarrierY", amount = price }))
            case Err(_) => Err(FetchShippingRatesError.FetchShippingRatesFailed)
        }

    pub def fetchZ(shipment: Shipment): Result[FetchShippingRatesError, ShippingRate] \ CarrierZApiClient =
        let Shipment({
            destinationPostalCode = PostalCode(code),
            weight = Weight(weight)
        }) = shipment;
        match CarrierZApiClient.fetchRate(CarrierZRateRequest.CarrierZRateRequest({
            postalCode = code,
            weight = weight
        })) {
            case Ok(CarrierZRateResponse.CarrierZRateResponse({ amount = amount, serviceCode = _ })) =>
                Ok(ShippingRate({ carrier = "CarrierZ", amount = amount }))
            case Err(_) => Err(FetchShippingRatesError.FetchShippingRatesFailed)
        }

    pub def fetchShippingRates(
        shipment: Shipment,
        xEnvironment: CarrierXApiEnvironment,
        yEnvironment: CarrierYApiEnvironment,
        zEnvironment: CarrierZApiEnvironment
    ): Result[FetchShippingRatesError, ShippingRates] \ {Chan, NonDet, IO} =
        fetchShippingRatesConcurrently(
            () -> runCarrierXApiClient(xEnvironment, () -> fetchX(shipment)),
            () -> runCarrierYApiClient(yEnvironment, () -> fetchY(shipment)),
            () -> runCarrierZApiClient(zEnvironment, () -> fetchZ(shipment))
        )

    pub def fetchShippingRatesConcurrently(
        xAction: Unit -> Result[FetchShippingRatesError, ShippingRate] \ IO,
        yAction: Unit -> Result[FetchShippingRatesError, ShippingRate] \ IO,
        zAction: Unit -> Result[FetchShippingRatesError, ShippingRate] \ IO
    ): Result[FetchShippingRatesError, ShippingRates] \ {Chan, NonDet, IO} =
        region rc {
            let (tx, rx) = Channel.buffered(1);
            let (ty, ry) = Channel.buffered(1);
            let (tz, rz) = Channel.buffered(1);
            spawn Channel.send(xAction(), tx) @ rc;
            spawn Channel.send(yAction(), ty) @ rc;
            spawn Channel.send(zAction(), tz) @ rc;
            match (Channel.recv(rx), Channel.recv(ry), Channel.recv(rz)) {
                case (Ok(x), Ok(y), Ok(z)) => Ok(ShippingRates(x, y :: z :: Nil))
                case _ => Err(FetchShippingRatesError.FetchShippingRatesFailed)
            }
        }
}
