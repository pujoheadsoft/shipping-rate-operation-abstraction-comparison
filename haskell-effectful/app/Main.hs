module Main where

import           Domain.UserId
import           Domain.Weight
import qualified Driver.CarrierXApiClientDriver as XDriver
import qualified Driver.CarrierYApiClientDriver as YDriver
import qualified Driver.CarrierZApiClientDriver as ZDriver
import qualified Driver.UserApiClientDriver     as UserDriver
import           Effectful
import           Effectful.Concurrent.Async     (runConcurrent)
import           Effectful.Error.Static
import qualified Gateway.PostalCodeGateway      as PostalGateway
import qualified Gateway.ShippingRatesGateway   as Gateway
import           UseCase.GetCheapestShippingRate

main :: IO ()
main = do
  result <- runEff
    $ runErrorNoCallStack @GetCheapestShippingRateError
    $ runConcurrent
    $ ZDriver.runCarrierZApiClient
      (ZDriver.CarrierZApiEnvironment "https://carrier-z.example.com")
    $ YDriver.runCarrierYApiClient
      (YDriver.CarrierYApiEnvironment "https://carrier-y.example.com")
    $ XDriver.runCarrierXApiClient
      (XDriver.CarrierXApiEnvironment "https://carrier-x.example.com")
    $ UserDriver.runUserApiClient
      (UserDriver.UserApiEnvironment "https://users.example.com")
    $ Gateway.runShippingRatePort
    $ PostalGateway.runPostalCodePort
    $ getCheapestShippingRate (UserId "user-123") (Weight 1000)
  print result
