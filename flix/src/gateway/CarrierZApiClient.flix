enum CarrierZRateRequest with Eq, ToString { case CarrierZRateRequest(String, Int32) }
enum CarrierZRateResponse with Eq, ToString { case CarrierZRateResponse(Int32, String) }
enum CarrierZApiError with Eq, ToString { case CarrierZApiOperationFailed }
eff CarrierZApiClient {
    def fetchRate(request: CarrierZRateRequest): Result[CarrierZApiError, CarrierZRateResponse]
}
