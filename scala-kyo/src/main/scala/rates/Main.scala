package rates

import kyo.*
import rates.domain.*
import rates.driver.*
import rates.gateway.*
import rates.usecase.*

object Main extends KyoApp:
  private def getEnv(name: String, defaultValue: String): String = sys.env.getOrElse(name, defaultValue)

  private val userApiEnvironment = UserApiEnvironment(getEnv("USER_API_BASE_URL", "http://localhost:8081"))
  private val carrierXEnvironment = CarrierXApiEnvironment(getEnv("CARRIER_X_API_BASE_URL", "http://localhost:8082"))
  private val carrierYEnvironment = CarrierYApiEnvironment(getEnv("CARRIER_Y_API_BASE_URL", "http://localhost:8083"))
  private val carrierZEnvironment = CarrierZApiEnvironment(getEnv("CARRIER_Z_API_BASE_URL", "http://localhost:8084"))

  run {
    GetCheapestShippingRate(UserId("user-123"), Weight(1000)).handle(
      PostalCodeGateway.run(_),
      UserApiClientDriver.run(userApiEnvironment)(_),
      ShippingRatesGateway.run(_),
      CarrierXApiClientDriver.run(carrierXEnvironment)(_),
      CarrierYApiClientDriver.run(carrierYEnvironment)(_),
      CarrierZApiClientDriver.run(carrierZEnvironment)(_),
      Abort.run[GetCheapestShippingRateError](_)
    ).map {
      case Result.Success(rate) =>
        Console.use(_.println("一番安い送料の取得に成功しました。"))
          .andThen(Console.use(_.println(s"  ${rate.carrier}: ${rate.amount}円")))
      case Result.Failure(GetCheapestShippingRateError.ShippingDestinationNotFound) =>
        Console.use(_.println("配送先が登録されていません。"))
      case Result.Failure(GetCheapestShippingRateError.GetCheapestShippingRateFailed) =>
        Console.use(_.println("一番安い送料の取得に失敗しました。"))
      case Result.Panic(error) => throw error
    }
  }
