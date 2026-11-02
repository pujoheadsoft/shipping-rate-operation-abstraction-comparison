pub mod Gateway.CarrierYApiClient {
    pub eff CarrierYApiClient {
        def fetchRate(request: CarrierYRateRequest): Result[CarrierYApiError, CarrierYRateResponse]
    }

    pub enum CarrierYRateRequest({
        postalCode = String,
        weight = Int32
    })

    pub enum CarrierYRateResponse({
        price = Int32,
        serviceName = String
    })

    instance Eq[CarrierYRateResponse] {
        pub def eq(x: CarrierYRateResponse, y: CarrierYRateResponse): Bool =
            let CarrierYRateResponse.CarrierYRateResponse(xResponse) = x;
            let CarrierYRateResponse.CarrierYRateResponse(yResponse) = y;
            xResponse#price == yResponse#price and
                xResponse#serviceName == yResponse#serviceName
    }

    instance ToString[CarrierYRateResponse] {
        pub def toString(response: CarrierYRateResponse): String =
            let CarrierYRateResponse.CarrierYRateResponse(value) = response;
            "CarrierYRateResponse({price = ${value#price}, serviceName = ${value#serviceName}})"
    }

    pub enum CarrierYApiError with Eq, ToString {
        case CarrierYApiOperationFailed
    }
}
