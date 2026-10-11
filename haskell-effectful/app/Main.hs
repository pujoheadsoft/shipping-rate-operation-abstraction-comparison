module Main where

import           Domain.Shipment
import qualified Driver.CarrierXApiClientDriver as XDriver
import qualified Driver.CarrierYApiClientDriver as YDriver
import qualified Driver.CarrierZApiClientDriver as ZDriver
import           Effectful
import           Effectful.Concurrent.Async     (runConcurrent)
import           Effectful.Error.Static
import qualified Gateway.ShippingRatesGateway   as Gateway
import           UseCase.GetShippingRates

main :: IO ()
main = do
  result <- runEff
    $ runErrorNoCallStack @GetShippingRatesError
    $ runConcurrent
    $ ZDriver.runCarrierZApiClient
      (ZDriver.CarrierZApiEnvironment "https://carrier-z.example.com")
    $ YDriver.runCarrierYApiClient
      (YDriver.CarrierYApiEnvironment "https://carrier-y.example.com")
    $ XDriver.runCarrierXApiClient
      (XDriver.CarrierXApiEnvironment "https://carrier-x.example.com")
    $ Gateway.runShippingRatePort
    $ getShippingRates
    $ Shipment "111-1111" 1000
  print result
