pub mod Gateway.CarrierZApiClient {
    pub eff CarrierZApiClient {
        def fetchRate(request: CarrierZRateRequest): Result[CarrierZApiError, CarrierZRateResponse]
    }

    pub enum CarrierZRateRequest with Eq, ToString {
        case CarrierZRateRequest(String, Int32)
    }

    pub enum CarrierZRateResponse with Eq, ToString {
        case CarrierZRateResponse(Int32, String)
    }

    pub enum CarrierZApiError with Eq, ToString {
        case CarrierZApiOperationFailed
    }
}
