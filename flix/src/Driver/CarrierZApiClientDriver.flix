pub mod Driver.CarrierZApiClientDriver {
    use Driver.DriverError.DriverError
    use Driver.HttpClient.postJson
    use Gateway.CarrierZApiClient.{CarrierZApiClient, CarrierZApiError, CarrierZRateRequest, CarrierZRateResponse}
    use Util.Json
    use Util.Json.FromJson
    use Util.Json.Json.{JNumber, JObject, JString}
    use Util.Json.JsonError

    pub enum CarrierZApiEnvironment({ baseUrl = String })

    enum CarrierZRateResponseJson({
        amount = Int32,
        serviceCode = String
    })

    instance FromJson[CarrierZRateResponseJson] {
        pub def fromJson(json: Json): Result[JsonError, CarrierZRateResponseJson] =
            forM (
                amount <- FromJson.decodeAtKey("amount", json);
                serviceCode <- FromJson.decodeAtKey("serviceCode", json)
            ) yield CarrierZRateResponseJson.CarrierZRateResponseJson({
                amount = amount,
                serviceCode = serviceCode
            })
    }

    pub def runCarrierZApiClient(
        environment: CarrierZApiEnvironment,
        action: Unit -> a \ CarrierZApiClient
    ): a \ IO = run { action() } with handler CarrierZApiClient {
        def fetchRate(request, resume) = resume(performFetchRate(environment, request))
    }

    def performFetchRate(
        environment: CarrierZApiEnvironment,
        request: CarrierZRateRequest
    ): Result[CarrierZApiError, CarrierZRateResponse] \ IO =
        performCarrierZFetchRate(environment, request)
            |> Result.mapErr(_ -> CarrierZApiError.CarrierZApiOperationFailed)

    def performCarrierZFetchRate(
        environment: CarrierZApiEnvironment,
        request: CarrierZRateRequest
    ): Result[DriverError, CarrierZRateResponse] \ IO =
        let CarrierZApiEnvironment.CarrierZApiEnvironment({ baseUrl = baseUrl }) = environment;
        let CarrierZRateRequest.CarrierZRateRequest({
            postalCode = postalCode,
            weight = weight
        }) = request;
        let body = Json.toCompactString(JObject(Map#{
            "postalCode" => JString(postalCode),
            "weight" => JNumber(Int32.toBigDecimal(weight))
        }));
        postJson("${baseUrl}/shipping/quote", body)
            |> Result.map(toCarrierZRateResponse)

    def toCarrierZRateResponse(response: CarrierZRateResponseJson): CarrierZRateResponse =
        let CarrierZRateResponseJson.CarrierZRateResponseJson({
            amount = amount,
            serviceCode = serviceCode
        }) = response;
        CarrierZRateResponse.CarrierZRateResponse({
            amount = amount,
            serviceCode = serviceCode
        })
}
