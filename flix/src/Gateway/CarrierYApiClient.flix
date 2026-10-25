pub mod Gateway.CarrierYApiClient {
    pub eff CarrierYApiClient {
        def fetchRate(request: CarrierYRateRequest): Result[CarrierYApiError, CarrierYRateResponse]
    }

    pub enum CarrierYRateRequest with Eq, ToString {
        case CarrierYRateRequest(String, Int32)
    }

    pub enum CarrierYRateResponse with Eq, ToString {
        case CarrierYRateResponse(Int32, String)
    }

    pub enum CarrierYApiError with Eq, ToString {
        case CarrierYApiOperationFailed
    }
}
