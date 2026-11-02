pub mod Driver.CarrierXApiClientDriver {
    use Driver.DriverError.DriverError
    use Driver.HttpClient.postJson
    use Gateway.CarrierXApiClient.{CarrierXApiClient, CarrierXApiError, CarrierXRateRequest, CarrierXRateResponse}
    use Util.Json
    use Util.Json.FromJson
    use Util.Json.Json.{JNumber, JObject, JString}
    use Util.Json.JsonError

    pub enum CarrierXApiEnvironment({ baseUrl = String })

    enum CarrierXRateResponseJson({
        amount = Int32,
        serviceCode = String
    })

    instance FromJson[CarrierXRateResponseJson] {
        pub def fromJson(json: Json): Result[JsonError, CarrierXRateResponseJson] =
            forM (
                amount <- FromJson.decodeAtKey("amount", json);
                serviceCode <- FromJson.decodeAtKey("serviceCode", json)
            ) yield CarrierXRateResponseJson.CarrierXRateResponseJson({
                amount = amount,
                serviceCode = serviceCode
            })
    }

    pub def runCarrierXApiClient(
        environment: CarrierXApiEnvironment,
        action: Unit -> a \ CarrierXApiClient
    ): a \ IO = run { action() } with handler CarrierXApiClient {
        def fetchRate(request, resume) = resume(performFetchRate(environment, request))
    }

    def performFetchRate(
        environment: CarrierXApiEnvironment,
        request: CarrierXRateRequest
    ): Result[CarrierXApiError, CarrierXRateResponse] \ IO =
        performCarrierXFetchRate(environment, request)
            |> Result.mapErr(_ -> CarrierXApiError.CarrierXApiOperationFailed)

    def performCarrierXFetchRate(
        environment: CarrierXApiEnvironment,
        request: CarrierXRateRequest
    ): Result[DriverError, CarrierXRateResponse] \ IO =
        let CarrierXApiEnvironment.CarrierXApiEnvironment({ baseUrl = baseUrl }) = environment;
        let CarrierXRateRequest.CarrierXRateRequest({
            destination = destination,
            weightGrams = weightGrams
        }) = request;
        let body = Json.toCompactString(JObject(Map#{
            "destination" => JString(destination),
            "weightGrams" => JNumber(Int32.toBigDecimal(weightGrams))
        }));
        postJson("${baseUrl}/shipping-rates", body)
            |> Result.map(toCarrierXRateResponse)

    def toCarrierXRateResponse(response: CarrierXRateResponseJson): CarrierXRateResponse =
        let CarrierXRateResponseJson.CarrierXRateResponseJson({
            amount = amount,
            serviceCode = serviceCode
        }) = response;
        CarrierXRateResponse.CarrierXRateResponse({
            amount = amount,
            serviceCode = serviceCode
        })
}
