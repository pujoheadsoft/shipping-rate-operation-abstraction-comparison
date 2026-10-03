module Test.Main (main) where

import Prelude

import Effect (Effect)
import Test.Gateway.ShippingRatesGateway as ShippingRatesGateway
import Test.Spec.Reporter.Console (consoleReporter)
import Test.Spec.Runner.Node (runSpecAndExitProcess)
import Test.UseCase.GetShippingRates as GetShippingRates

main :: Effect Unit
main = runSpecAndExitProcess [ consoleReporter ] do
  GetShippingRates.spec
  ShippingRatesGateway.spec
