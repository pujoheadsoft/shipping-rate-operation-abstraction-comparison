module Test.Main where

import Prelude
import Effect (Effect)
import Test.Gateway.ShippingRatesGateway as ShippingRatesGateway
import Test.Gateway.ShippingRatesGatewayConcurrency as Concurrency
import Test.Spec.Reporter.Console (consoleReporter)
import Test.UseCase.GetShippingRates as GetShippingRates
import Test.Spec.Runner.Node (runSpecAndExitProcess)

main :: Effect Unit
main = runSpecAndExitProcess [ consoleReporter ] do
  GetShippingRates.spec
  ShippingRatesGateway.spec
  Concurrency.spec
