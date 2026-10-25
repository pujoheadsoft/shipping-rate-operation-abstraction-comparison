pub mod Gateway.CarrierXApiClient {
    pub eff CarrierXApiClient {
        def fetchRate(request: CarrierXRateRequest): Result[CarrierXApiError, CarrierXRateResponse]
    }

    pub enum CarrierXRateRequest with Eq, ToString {
        case CarrierXRateRequest(String, Int32)
    }

    pub enum CarrierXRateResponse with Eq, ToString {
        case CarrierXRateResponse(Int32, String)
    }

    pub enum CarrierXApiError with Eq, ToString {
        case CarrierXApiOperationFailed
    }
}
