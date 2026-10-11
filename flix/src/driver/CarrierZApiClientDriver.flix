use Util.Json
use Util.Json.Json.{JNumber, JObject, JString}

enum CarrierZApiEnvironment { case CarrierZApiEnvironment(String) }

def runCarrierZApiClient(
    action: Unit -> a \ CarrierZApiClient,
    clientHandler: CarrierZRateRequest -> Result[CarrierZApiError, CarrierZRateResponse] \ IO
): a \ IO = run { action() } with handler CarrierZApiClient {
    def fetchRate(request, resume) = resume(clientHandler(request))
}

def carrierZApiClientHandler(
    environment: CarrierZApiEnvironment,
    request: CarrierZRateRequest
): Result[CarrierZApiError, CarrierZRateResponse] \ IO =
    match performCarrierZFetchRate(environment, request) {
        case Ok(response) => Ok(response)
        case Err(_) => Err(CarrierZApiError.CarrierZApiOperationFailed)
    }

def performCarrierZFetchRate(
    environment: CarrierZApiEnvironment,
    request: CarrierZRateRequest
): Result[DriverError, CarrierZRateResponse] \ IO =
    let CarrierZApiEnvironment.CarrierZApiEnvironment(baseUrl) = environment;
    let CarrierZRateRequest.CarrierZRateRequest(postalCode, weight) = request;
    let body = Json.toCompactString(JObject(Map#{
        "postalCode" => JString(postalCode),
        "weight" => JNumber(Int32.toBigDecimal(weight))
    }));
    match postJson("${baseUrl}/shipping/quote", body) {
        case Ok(value) => decodeZ(value)
        case Err(error) => Err(error)
    }

def decodeZ(body: String): Result[DriverError, CarrierZRateResponse] = match Json.parse(body) {
    case Ok(JObject(fields)) => match (Map.get("amount", fields), Map.get("serviceCode", fields)) {
        case (Some(JNumber(amount)), Some(JString(serviceCode))) => match BigDecimal.tryToInt32(amount) {
            case Some(value) => Ok(CarrierZRateResponse.CarrierZRateResponse(value, serviceCode))
            case None => Err(DriverError.DriverOperationFailed)
        }
        case _ => Err(DriverError.DriverOperationFailed)
    }
    case _ => Err(DriverError.DriverOperationFailed)
}
