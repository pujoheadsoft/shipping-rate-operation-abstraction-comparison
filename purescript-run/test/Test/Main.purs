module Test.Main where

import Prelude
import Effect (Effect)
import Test.Domain.ShippingRates as ShippingRates
import Test.Gateway.PostalCodeGateway as PostalCodeGateway
import Test.Gateway.ShippingRatesGateway as ShippingRatesGateway
import Test.Gateway.ShippingRatesGatewayConcurrency as Concurrency
import Test.Spec.Reporter.Console (consoleReporter)
import Test.UseCase.GetCheapestShippingRate as GetCheapestShippingRate
import Test.Spec.Runner.Node (runSpecAndExitProcess)

main :: Effect Unit
main = runSpecAndExitProcess [ consoleReporter ] do
  ShippingRates.spec
  GetCheapestShippingRate.spec
  PostalCodeGateway.spec
  ShippingRatesGateway.spec
  Concurrency.spec
