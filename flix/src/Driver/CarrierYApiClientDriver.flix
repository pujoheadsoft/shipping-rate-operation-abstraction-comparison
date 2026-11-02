pub mod Driver.CarrierYApiClientDriver {
    use Driver.DriverError.DriverError
    use Driver.HttpClient.postJson
    use Gateway.CarrierYApiClient.{CarrierYApiClient, CarrierYApiError, CarrierYRateRequest, CarrierYRateResponse}
    use Util.Json
    use Util.Json.FromJson
    use Util.Json.Json.{JNumber, JObject, JString}
    use Util.Json.JsonError

    pub enum CarrierYApiEnvironment({ baseUrl = String })

    enum CarrierYRateResponseJson({
        price = Int32,
        serviceName = String
    })

    instance FromJson[CarrierYRateResponseJson] {
        pub def fromJson(json: Json): Result[JsonError, CarrierYRateResponseJson] =
            forM (
                price <- FromJson.decodeAtKey("price", json);
                serviceName <- FromJson.decodeAtKey("serviceName", json)
            ) yield CarrierYRateResponseJson.CarrierYRateResponseJson({
                price = price,
                serviceName = serviceName
            })
    }

    pub def runCarrierYApiClient(
        environment: CarrierYApiEnvironment,
        action: Unit -> a \ CarrierYApiClient
    ): a \ IO = run { action() } with handler CarrierYApiClient {
        def fetchRate(request, resume) = resume(performFetchRate(environment, request))
    }

    def performFetchRate(
        environment: CarrierYApiEnvironment,
        request: CarrierYRateRequest
    ): Result[CarrierYApiError, CarrierYRateResponse] \ IO =
        performCarrierYFetchRate(environment, request)
            |> Result.mapErr(_ -> CarrierYApiError.CarrierYApiOperationFailed)

    def performCarrierYFetchRate(
        environment: CarrierYApiEnvironment,
        request: CarrierYRateRequest
    ): Result[DriverError, CarrierYRateResponse] \ IO =
        let CarrierYApiEnvironment.CarrierYApiEnvironment({ baseUrl = baseUrl }) = environment;
        let CarrierYRateRequest.CarrierYRateRequest({
            postalCode = postalCode,
            weight = weight
        }) = request;
        let body = Json.toCompactString(JObject(Map#{
            "postalCode" => JString(postalCode),
            "weight" => JNumber(Int32.toBigDecimal(weight))
        }));
        postJson("${baseUrl}/rates/quote", body)
            |> Result.map(toCarrierYRateResponse)

    def toCarrierYRateResponse(response: CarrierYRateResponseJson): CarrierYRateResponse =
        let CarrierYRateResponseJson.CarrierYRateResponseJson({
            price = price,
            serviceName = serviceName
        }) = response;
        CarrierYRateResponse.CarrierYRateResponse({
            price = price,
            serviceName = serviceName
        })
}
