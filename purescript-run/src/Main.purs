module Main where

import Prelude
import Domain.UserId (UserId(..))
import Domain.Weight (Weight(..))
import Driver.CarrierXApiClientDriver (runCarrierXApiClient)
import Driver.CarrierYApiClientDriver (runCarrierYApiClient)
import Driver.CarrierZApiClientDriver (runCarrierZApiClient)
import Driver.UserApiClientDriver (runUserApiClient)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Run (Run, runBaseAff)
import Run as Run
import Run.Parallel (runParallel)
import Gateway.ApplicationGateway (API_CLIENTS, runApplicationPorts)
import Run.Except as RunExcept
import UseCase.GetCheapestShippingRate (getCheapestShippingRate)

main :: Effect Unit
main = launchAff_ do
  let
    interpretApis
      :: Run (API_CLIENTS ())
      ~> Aff
    interpretApis = runBaseAff
      <<< runCarrierZApiClient { baseUrl: "https://carrier-z.example.com" }
      <<< runCarrierYApiClient { baseUrl: "https://carrier-y.example.com" }
      <<< runCarrierXApiClient { baseUrl: "https://carrier-x.example.com" }
      <<< runUserApiClient { baseUrl: "https://users.example.com" }
      <<< Run.expand
    program = runApplicationPorts
      $ RunExcept.runExcept
      $ getCheapestShippingRate (UserId "user-123") (Weight 1000)
  result <- runParallel interpretApis program
  liftEffect $ log $ show result
