module Main where

import           Domain.Shipment
import qualified Driver.CarrierXApiClientDriver as XDriver
import qualified Driver.CarrierYApiClientDriver as YDriver
import qualified Driver.CarrierZApiClientDriver as ZDriver
import qualified Gateway.ShippingRatesGateway   as Gateway
import           Polysemy
import           Polysemy.Async
import           Polysemy.Error
import           Polysemy.Resource              (resourceToIOFinal)
import           UseCase.GetShippingRates

main :: IO ()
main = runApplication (Shipment "111-1111" 1000) >>= print
  where
    runApplication = runFinal
      . embedToFinal @IO
      . resourceToIOFinal
      . asyncToIOFinal
      . runError @GetShippingRatesError
      . ZDriver.runCarrierZApiClient
        (ZDriver.CarrierZApiEnvironment "https://carrier-z.example.com")
      . YDriver.runCarrierYApiClient
        (YDriver.CarrierYApiEnvironment "https://carrier-y.example.com")
      . XDriver.runCarrierXApiClient
        (XDriver.CarrierXApiEnvironment "https://carrier-x.example.com")
      . Gateway.runShippingRatePort
      . getShippingRates
