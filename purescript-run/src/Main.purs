module Main where

import Prelude
import Domain.Shipment (Shipment(..))
import Driver.CarrierXApiClientDriver (runCarrierXApiClient)
import Driver.CarrierYApiClientDriver (runCarrierYApiClient)
import Driver.CarrierZApiClientDriver (runCarrierZApiClient)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Run (Run, runBaseAff)
import Run as Run
import Run.Parallel (runParallel)
import Gateway.ShippingRatesGateway (runShippingRatePort)
import Gateway.ShippingRatesGateway as Gateway
import UseCase.GetShippingRates (getShippingRates)

main :: Effect Unit
main = launchAff_ do
  let
    shipment = Shipment { destinationPostalCode: "111-1111", weight: 1000 }
    interpretCarriers
      :: Run (Gateway.CARRIER_API_CLIENTS ())
      ~> Aff
    interpretCarriers = runBaseAff
      <<< runCarrierZApiClient { baseUrl: "https://carrier-z.example.com" }
      <<< runCarrierYApiClient { baseUrl: "https://carrier-y.example.com" }
      <<< runCarrierXApiClient { baseUrl: "https://carrier-x.example.com" }
      <<< Run.expand
    program = runShippingRatePort $ getShippingRates shipment
  result <- runParallel interpretCarriers program
  liftEffect $ log $ show result
