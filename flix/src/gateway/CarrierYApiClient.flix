enum CarrierYRateRequest with Eq, ToString { case CarrierYRateRequest(String, Int32) }
enum CarrierYRateResponse with Eq, ToString { case CarrierYRateResponse(Int32, String) }
enum CarrierYApiError with Eq, ToString { case CarrierYApiOperationFailed }
eff CarrierYApiClient {
    def fetchRate(request: CarrierYRateRequest): Result[CarrierYApiError, CarrierYRateResponse]
}
