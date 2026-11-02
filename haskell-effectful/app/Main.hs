module Main where

import           Domain.UserId
import           Domain.Weight
import           Domain.ShippingRate            (ShippingRate (..))
import qualified Driver.CarrierXApiClientDriver as XDriver
import qualified Driver.CarrierYApiClientDriver as YDriver
import qualified Driver.CarrierZApiClientDriver as ZDriver
import qualified Driver.UserApiClientDriver     as UserDriver
import           Effectful
import           Effectful.Concurrent.Async     (runConcurrent)
import           Effectful.Error.Static
import qualified Gateway.PostalCodeGateway      as PostalGateway
import qualified Gateway.ShippingRatesGateway   as Gateway
import           System.Environment             (lookupEnv)
import           UseCase.GetCheapestShippingRate

main :: IO ()
main = do
  userApiBaseUrl <- getEnv "USER_API_BASE_URL" "http://localhost:8081"
  carrierXApiBaseUrl <- getEnv "CARRIER_X_API_BASE_URL" "http://localhost:8082"
  carrierYApiBaseUrl <- getEnv "CARRIER_Y_API_BASE_URL" "http://localhost:8083"
  carrierZApiBaseUrl <- getEnv "CARRIER_Z_API_BASE_URL" "http://localhost:8084"
  result <- runEff
    $ runErrorNoCallStack @GetCheapestShippingRateError
    $ runConcurrent
    $ ZDriver.runCarrierZApiClient
      (ZDriver.CarrierZApiEnvironment carrierZApiBaseUrl)
    $ YDriver.runCarrierYApiClient
      (YDriver.CarrierYApiEnvironment carrierYApiBaseUrl)
    $ XDriver.runCarrierXApiClient
      (XDriver.CarrierXApiEnvironment carrierXApiBaseUrl)
    $ UserDriver.runUserApiClient
      (UserDriver.UserApiEnvironment userApiBaseUrl)
    $ Gateway.runShippingRatePort
    $ PostalGateway.runPostalCodePort
    $ getCheapestShippingRate (UserId "user-123") (Weight 1000)
  printResult result

getEnv :: String -> String -> IO String
getEnv name defaultValue = maybe defaultValue id <$> lookupEnv name

printResult :: Either GetCheapestShippingRateError ShippingRate -> IO ()
printResult (Right (ShippingRate rateCarrier rateAmount)) = do
  putStrLn "一番安い送料の取得に成功しました。"
  putStrLn $ "  " <> rateCarrier <> ": " <> show rateAmount <> "円"
printResult (Left ShippingDestinationNotFound) =
  putStrLn "配送先が登録されていません。"
printResult (Left GetCheapestShippingRateFailed) =
  putStrLn "一番安い送料の取得に失敗しました。"
