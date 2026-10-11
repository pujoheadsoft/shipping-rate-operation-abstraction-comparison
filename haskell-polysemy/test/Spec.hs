module Main where

import qualified Gateway.ShippingRatesGatewayConcurrencySpec as Concurrency
import qualified Gateway.ShippingRatesGatewaySpec            as Gateway
import           Test.Hspec                                  (hspec)
import qualified UseCase.GetShippingRatesSpec                as UseCase

main :: IO ()
main = hspec $ UseCase.spec >> Gateway.spec >> Concurrency.spec
