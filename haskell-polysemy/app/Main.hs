module Main where

import           Domain.UserId
import           Domain.Weight
import qualified Driver.CarrierXApiClientDriver as XDriver
import qualified Driver.CarrierYApiClientDriver as YDriver
import qualified Driver.CarrierZApiClientDriver as ZDriver
import qualified Driver.UserApiClientDriver     as UserDriver
import qualified Gateway.PostalCodeGateway      as PostalGateway
import qualified Gateway.ShippingRatesGateway   as Gateway
import           Polysemy
import           Polysemy.Async
import           Polysemy.Error
import           Polysemy.Resource              (resourceToIOFinal)
import           UseCase.GetCheapestShippingRate

main :: IO ()
main = runApplication (UserId "user-123") (Weight 1000) >>= print
  where
    runApplication userId weight = runFinal
      . embedToFinal @IO
      . resourceToIOFinal
      . asyncToIOFinal
      . runError @GetCheapestShippingRateError
      . ZDriver.runCarrierZApiClient
        (ZDriver.CarrierZApiEnvironment "https://carrier-z.example.com")
      . YDriver.runCarrierYApiClient
        (YDriver.CarrierYApiEnvironment "https://carrier-y.example.com")
      . XDriver.runCarrierXApiClient
        (XDriver.CarrierXApiEnvironment "https://carrier-x.example.com")
      . UserDriver.runUserApiClient
        (UserDriver.UserApiEnvironment "https://users.example.com")
      . Gateway.runShippingRatePort
      . PostalGateway.runPostalCodePort
      $ getCheapestShippingRate userId weight
