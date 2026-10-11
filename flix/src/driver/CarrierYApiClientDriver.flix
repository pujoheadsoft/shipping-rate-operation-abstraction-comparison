use Util.Json
use Util.Json.Json.{JNumber, JObject, JString}

enum CarrierYApiEnvironment { case CarrierYApiEnvironment(String) }

def runCarrierYApiClient(
    action: Unit -> a \ CarrierYApiClient,
    clientHandler: CarrierYRateRequest -> Result[CarrierYApiError, CarrierYRateResponse] \ IO
): a \ IO = run { action() } with handler CarrierYApiClient {
    def fetchRate(request, resume) = resume(clientHandler(request))
}

def carrierYApiClientHandler(
    environment: CarrierYApiEnvironment,
    request: CarrierYRateRequest
): Result[CarrierYApiError, CarrierYRateResponse] \ IO =
    match performCarrierYFetchRate(environment, request) {
        case Ok(response) => Ok(response)
        case Err(_) => Err(CarrierYApiError.CarrierYApiOperationFailed)
    }

def performCarrierYFetchRate(
    environment: CarrierYApiEnvironment,
    request: CarrierYRateRequest
): Result[DriverError, CarrierYRateResponse] \ IO =
    let CarrierYApiEnvironment.CarrierYApiEnvironment(baseUrl) = environment;
    let CarrierYRateRequest.CarrierYRateRequest(postalCode, weight) = request;
    let body = Json.toCompactString(JObject(Map#{
        "postalCode" => JString(postalCode),
        "weight" => JNumber(Int32.toBigDecimal(weight))
    }));
    match postJson("${baseUrl}/rates/quote", body) {
        case Ok(value) => decodeY(value)
        case Err(error) => Err(error)
    }

def decodeY(body: String): Result[DriverError, CarrierYRateResponse] = match Json.parse(body) {
    case Ok(JObject(fields)) => match (Map.get("price", fields), Map.get("serviceName", fields)) {
        case (Some(JNumber(price)), Some(JString(serviceName))) => match BigDecimal.tryToInt32(price) {
            case Some(value) => Ok(CarrierYRateResponse.CarrierYRateResponse(value, serviceName))
            case None => Err(DriverError.DriverOperationFailed)
        }
        case _ => Err(DriverError.DriverOperationFailed)
    }
    case _ => Err(DriverError.DriverOperationFailed)
}
