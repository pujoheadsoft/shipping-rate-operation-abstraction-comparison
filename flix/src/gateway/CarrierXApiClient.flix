enum CarrierXRateRequest with Eq, ToString { case CarrierXRateRequest(String, Int32) }
enum CarrierXRateResponse with Eq, ToString { case CarrierXRateResponse(Int32, String) }
enum CarrierXApiError with Eq, ToString { case CarrierXApiOperationFailed }
eff CarrierXApiClient {
    def fetchRate(request: CarrierXRateRequest): Result[CarrierXApiError, CarrierXRateResponse]
}
