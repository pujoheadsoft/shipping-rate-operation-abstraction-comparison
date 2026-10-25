module Main where

import qualified Domain.ShippingRatesSpec                  as ShippingRates
import qualified Gateway.PostalCodeGatewaySpec             as PostalCodeGateway
import qualified Gateway.ShippingRatesGatewayConcurrencySpec as Concurrency
import qualified Gateway.ShippingRatesGatewaySpec            as Gateway
import           Test.Hspec                                  (hspec)
import qualified UseCase.GetCheapestShippingRateSpec        as UseCase

main :: IO ()
main = hspec
  $ ShippingRates.spec
  >> UseCase.spec
  >> PostalCodeGateway.spec
  >> Gateway.spec
  >> Concurrency.spec
