pub mod Gateway.CarrierXApiClient {
    pub eff CarrierXApiClient {
        def fetchRate(request: CarrierXRateRequest): Result[CarrierXApiError, CarrierXRateResponse]
    }

    pub enum CarrierXRateRequest({
        destination = String,
        weightGrams = Int32
    })

    pub enum CarrierXRateResponse({
        amount = Int32,
        serviceCode = String
    })

    instance Eq[CarrierXRateResponse] {
        pub def eq(x: CarrierXRateResponse, y: CarrierXRateResponse): Bool =
            let CarrierXRateResponse.CarrierXRateResponse(xResponse) = x;
            let CarrierXRateResponse.CarrierXRateResponse(yResponse) = y;
            xResponse#amount == yResponse#amount and
                xResponse#serviceCode == yResponse#serviceCode
    }

    instance ToString[CarrierXRateResponse] {
        pub def toString(response: CarrierXRateResponse): String =
            let CarrierXRateResponse.CarrierXRateResponse(value) = response;
            "CarrierXRateResponse({amount = ${value#amount}, serviceCode = ${value#serviceCode}})"
    }

    pub enum CarrierXApiError with Eq, ToString {
        case CarrierXApiOperationFailed
    }
}
