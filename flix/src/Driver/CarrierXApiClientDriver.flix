pub mod Driver.CarrierXApiClientDriver {
    use Driver.DriverError.DriverError
    use Driver.HttpClient.postJson
    use Gateway.CarrierXApiClient.{CarrierXApiClient, CarrierXApiError, CarrierXRateRequest, CarrierXRateResponse}
    use Util.Json
    use Util.Json.Json.{JNumber, JObject, JString}

    pub enum CarrierXApiEnvironment {
        case CarrierXApiEnvironment(String)
    }

    pub def runCarrierXApiClient(
        action: Unit -> a \ CarrierXApiClient,
        clientHandler: CarrierXRateRequest -> Result[CarrierXApiError, CarrierXRateResponse] \ IO
    ): a \ IO = run { action() } with handler CarrierXApiClient {
        def fetchRate(request, resume) = resume(clientHandler(request))
    }

    pub def carrierXApiClientHandler(
        environment: CarrierXApiEnvironment,
        request: CarrierXRateRequest
    ): Result[CarrierXApiError, CarrierXRateResponse] \ IO =
        match performCarrierXFetchRate(environment, request) {
            case Ok(response) => Ok(response)
            case Err(_) => Err(CarrierXApiError.CarrierXApiOperationFailed)
        }

    def performCarrierXFetchRate(
        environment: CarrierXApiEnvironment,
        request: CarrierXRateRequest
    ): Result[DriverError, CarrierXRateResponse] \ IO =
        let CarrierXApiEnvironment.CarrierXApiEnvironment(baseUrl) = environment;
        let CarrierXRateRequest.CarrierXRateRequest(destination, weightGrams) = request;
        let body = Json.toCompactString(JObject(Map#{
            "destination" => JString(destination),
            "weightGrams" => JNumber(Int32.toBigDecimal(weightGrams))
        }));
        match postJson("${baseUrl}/shipping-rates", body) {
            case Ok(value) => decodeX(value)
            case Err(error) => Err(error)
        }

    def decodeX(body: String): Result[DriverError, CarrierXRateResponse] = match Json.parse(body) {
        case Ok(JObject(fields)) => match (Map.get("amount", fields), Map.get("serviceCode", fields)) {
            case (Some(JNumber(amount)), Some(JString(serviceCode))) => match BigDecimal.tryToInt32(amount) {
                case Some(value) => Ok(CarrierXRateResponse.CarrierXRateResponse(value, serviceCode))
                case None => Err(DriverError.DriverOperationFailed)
            }
            case _ => Err(DriverError.DriverOperationFailed)
        }
        case _ => Err(DriverError.DriverOperationFailed)
    }
}
