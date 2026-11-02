pub mod UseCase.GetCheapestShippingRate {
    use Domain.PostalCode
    use Domain.Shipment.Shipment
    use Domain.ShippingRate
    use Domain.ShippingRates.ShippingRates
    use Domain.ShippingRates.findCheapest
    use Domain.UserId
    use Domain.Weight
    use UseCase.ShippingRatePort.fetchShippingRates
    use UseCase.PostalCodePort.fetchPostalCodeByUserId
    use UseCase.PostalCodePort.FetchPostalCodeError
    use UseCase.PostalCodePort
    use UseCase.ShippingRatePort

    pub def getCheapestShippingRate(userId: UserId, weight: Weight): 
        Result[GetCheapestShippingRateError, ShippingRate] \ {ShippingRatePort, PostalCodePort} =
        userId
            |> fetchPostalCode
            |> Result.flatMap(fetchShippingRatesFor(weight))
            |> Result.map(findCheapest)

    def fetchPostalCode(userId: UserId):
        Result[GetCheapestShippingRateError, PostalCode] \ PostalCodePort =
        fetchPostalCodeByUserId(userId)
            |> Result.mapErr(toUseCasePostalCodeError)

    def fetchShippingRatesFor(weight: Weight, postalCode: PostalCode):
        Result[GetCheapestShippingRateError, ShippingRates] \ ShippingRatePort =
        let shipment = Shipment({ destinationPostalCode = postalCode, weight = weight });
        fetchShippingRates(shipment)
            |> Result.mapErr(_ -> GetCheapestShippingRateError.GetCheapestShippingRateFailed)

    def toUseCasePostalCodeError(error: FetchPostalCodeError): GetCheapestShippingRateError =
        match error {
            case FetchPostalCodeError.PostalCodeNotFound =>
                GetCheapestShippingRateError.ShippingDestinationNotFound
            case FetchPostalCodeError.FetchPostalCodeFailed =>
                GetCheapestShippingRateError.GetCheapestShippingRateFailed
        }

    pub enum GetCheapestShippingRateError with Eq, ToString {
        case ShippingDestinationNotFound
        case GetCheapestShippingRateFailed
    }

}
