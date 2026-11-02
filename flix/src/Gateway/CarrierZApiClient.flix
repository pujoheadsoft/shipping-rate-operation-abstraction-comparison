pub mod Gateway.CarrierZApiClient {
    pub eff CarrierZApiClient {
        def fetchRate(request: CarrierZRateRequest): Result[CarrierZApiError, CarrierZRateResponse]
    }

    pub enum CarrierZRateRequest({
        postalCode = String,
        weight = Int32
    })

    pub enum CarrierZRateResponse({
        amount = Int32,
        serviceCode = String
    })

    instance Eq[CarrierZRateResponse] {
        pub def eq(x: CarrierZRateResponse, y: CarrierZRateResponse): Bool =
            let CarrierZRateResponse.CarrierZRateResponse(xResponse) = x;
            let CarrierZRateResponse.CarrierZRateResponse(yResponse) = y;
            xResponse#amount == yResponse#amount and
                xResponse#serviceCode == yResponse#serviceCode
    }

    instance ToString[CarrierZRateResponse] {
        pub def toString(response: CarrierZRateResponse): String =
            let CarrierZRateResponse.CarrierZRateResponse(value) = response;
            "CarrierZRateResponse({amount = ${value#amount}, serviceCode = ${value#serviceCode}})"
    }

    pub enum CarrierZApiError with Eq, ToString {
        case CarrierZApiOperationFailed
    }
}
