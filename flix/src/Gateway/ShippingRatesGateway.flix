pub mod Gateway.ShippingRatesGateway {
    use Domain.PostalCode
    use Domain.Weight
    use Domain.Shipment
    use Domain.ShippingRate
    use Domain.ShippingRates
    use Driver.CarrierXApiClientDriver.runCarrierXApiClient
    use Driver.CarrierYApiClientDriver.runCarrierYApiClient
    use Driver.CarrierZApiClientDriver.runCarrierZApiClient
    use Gateway.CarrierXApiClient.{CarrierXApiClient, CarrierXApiError, CarrierXRateRequest, CarrierXRateResponse}
    use Gateway.CarrierYApiClient.{CarrierYApiClient, CarrierYApiError, CarrierYRateRequest, CarrierYRateResponse}
    use Gateway.CarrierZApiClient.{CarrierZApiClient, CarrierZApiError, CarrierZRateRequest, CarrierZRateResponse}
    use UseCase.ShippingRatePort.{FetchShippingRatesError, ShippingRatePort, handleWith}

    pub def runShippingRatePort(
        action: Unit -> a \ ShippingRatePort,
        xHandler: CarrierXRateRequest -> Result[CarrierXApiError, CarrierXRateResponse] \ IO,
        yHandler: CarrierYRateRequest -> Result[CarrierYApiError, CarrierYRateResponse] \ IO,
        zHandler: CarrierZRateRequest -> Result[CarrierZApiError, CarrierZRateResponse] \ IO
    ): a \ {Chan, NonDet, IO} =
        handleWith(action, shipment -> fetchShippingRates(shipment, xHandler, yHandler, zHandler))

    def fetchX(shipment: Shipment): Result[FetchShippingRatesError, ShippingRate] \ CarrierXApiClient =
        let Shipment(PostalCode(code), Weight(weight)) = shipment;
        match CarrierXApiClient.fetchRate(CarrierXRateRequest.CarrierXRateRequest(code, weight)) {
            case Ok(CarrierXRateResponse.CarrierXRateResponse(amount, _)) =>
                Ok(ShippingRate("CarrierX", amount))
            case Err(_) => Err(FetchShippingRatesError.FetchShippingRatesFailed)
        }

    def fetchY(shipment: Shipment): Result[FetchShippingRatesError, ShippingRate] \ CarrierYApiClient =
        let Shipment(PostalCode(code), Weight(weight)) = shipment;
        match CarrierYApiClient.fetchRate(CarrierYRateRequest.CarrierYRateRequest(code, weight)) {
            case Ok(CarrierYRateResponse.CarrierYRateResponse(price, _)) =>
                Ok(ShippingRate("CarrierY", price))
            case Err(_) => Err(FetchShippingRatesError.FetchShippingRatesFailed)
        }

    def fetchZ(shipment: Shipment): Result[FetchShippingRatesError, ShippingRate] \ CarrierZApiClient =
        let Shipment(PostalCode(code), Weight(weight)) = shipment;
        match CarrierZApiClient.fetchRate(CarrierZRateRequest.CarrierZRateRequest(code, weight)) {
            case Ok(CarrierZRateResponse.CarrierZRateResponse(amount, _)) =>
                Ok(ShippingRate("CarrierZ", amount))
            case Err(_) => Err(FetchShippingRatesError.FetchShippingRatesFailed)
        }

    pub def fetchShippingRates(
        shipment: Shipment,
        xHandler: CarrierXRateRequest -> Result[CarrierXApiError, CarrierXRateResponse] \ IO,
        yHandler: CarrierYRateRequest -> Result[CarrierYApiError, CarrierYRateResponse] \ IO,
        zHandler: CarrierZRateRequest -> Result[CarrierZApiError, CarrierZRateResponse] \ IO
    ): Result[FetchShippingRatesError, ShippingRates] \ {Chan, NonDet, IO} =
        region rc {
            let (tx, rx) = Channel.buffered(1);
            let (ty, ry) = Channel.buffered(1);
            let (tz, rz) = Channel.buffered(1);
            spawn Channel.send(runCarrierXApiClient(() -> fetchX(shipment), xHandler), tx) @ rc;
            spawn Channel.send(runCarrierYApiClient(() -> fetchY(shipment), yHandler), ty) @ rc;
            spawn Channel.send(runCarrierZApiClient(() -> fetchZ(shipment), zHandler), tz) @ rc;
            match (Channel.recv(rx), Channel.recv(ry), Channel.recv(rz)) {
                case (Ok(x), Ok(y), Ok(z)) => Ok(ShippingRates(x, y :: z :: Nil))
                case _ => Err(FetchShippingRatesError.FetchShippingRatesFailed)
            }
        }
}
