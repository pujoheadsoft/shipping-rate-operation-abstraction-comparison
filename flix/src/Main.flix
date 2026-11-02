use Domain.UserId.UserId
use Domain.Weight
use Domain.ShippingRate.ShippingRate
use Driver.CarrierXApiClientDriver.CarrierXApiEnvironment
use Driver.CarrierYApiClientDriver.CarrierYApiEnvironment
use Driver.CarrierZApiClientDriver.CarrierZApiEnvironment
use Driver.UserApiClientDriver.{UserApiEnvironment, runUserApiClient}
use Gateway.PostalCodeGateway.runPostalCodePort
use Gateway.ShippingRatesGateway.runShippingRatePort
use UseCase.GetCheapestShippingRate.{GetCheapestShippingRateError, getCheapestShippingRate}

def main(): Unit \ {Chan, NonDet, IO} =
    Sys.Env.runWithIO(() -> {
        let userId = UserId("user-123");
        let weight = Weight(1000);
        let userApiEnvironment = UserApiEnvironment.UserApiEnvironment({
            baseUrl = getEnv("USER_API_BASE_URL", "http://localhost:8081")
        });
        let xEnvironment = CarrierXApiEnvironment.CarrierXApiEnvironment({
            baseUrl = getEnv("CARRIER_X_API_BASE_URL", "http://localhost:8082")
        });
        let yEnvironment = CarrierYApiEnvironment.CarrierYApiEnvironment({
            baseUrl = getEnv("CARRIER_Y_API_BASE_URL", "http://localhost:8083")
        });
        let zEnvironment = CarrierZApiEnvironment.CarrierZApiEnvironment({
            baseUrl = getEnv("CARRIER_Z_API_BASE_URL", "http://localhost:8084")
        });
        let result = run {
            getCheapestShippingRate(userId, weight)
        } with runPostalCodePort
          with runUserApiClient(userApiEnvironment)
          with runShippingRatePort(
                xEnvironment,
                yEnvironment,
                zEnvironment
            );
        printResult(result)
    })

def printResult(result: Result[GetCheapestShippingRateError, ShippingRate]): Unit \ IO =
    match result {
        case Ok(ShippingRate.ShippingRate({ carrier = carrier, amount = amount })) =>
            println("一番安い送料の取得に成功しました。");
            println("  ${carrier}: ${amount}円")
        case Err(GetCheapestShippingRateError.ShippingDestinationNotFound) =>
            println("配送先が登録されていません。")
        case Err(GetCheapestShippingRateError.GetCheapestShippingRateFailed) =>
            println("一番安い送料の取得に失敗しました。")
    }

def getEnv(name: String, defaultValue: String): String \ Sys.Env.Env = match Sys.Env.getVar(name) {
    case Some(value) => value
    case None => defaultValue
}
