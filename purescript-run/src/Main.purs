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
import Data.Maybe (fromMaybe)
import Node.Process (lookupEnv)
import Run (Run, runBaseAff)
import Run as Run
import Run.Parallel (runParallel)
import Gateway.ApplicationGateway (API_CLIENTS, runApplicationPorts)
import Run.Except as RunExcept
import UseCase.GetCheapestShippingRate (getCheapestShippingRate)

main :: Effect Unit
main = do
  userApiBaseUrl <- getEnv "USER_API_BASE_URL" "http://localhost:8081"
  carrierXApiBaseUrl <- getEnv "CARRIER_X_API_BASE_URL" "http://localhost:8082"
  carrierYApiBaseUrl <- getEnv "CARRIER_Y_API_BASE_URL" "http://localhost:8083"
  carrierZApiBaseUrl <- getEnv "CARRIER_Z_API_BASE_URL" "http://localhost:8084"
  launchAff_ do
    let
      interpretApis
        :: Run (API_CLIENTS ())
        ~> Aff
      interpretApis = runBaseAff
        <<< runCarrierZApiClient { baseUrl: carrierZApiBaseUrl }
        <<< runCarrierYApiClient { baseUrl: carrierYApiBaseUrl }
        <<< runCarrierXApiClient { baseUrl: carrierXApiBaseUrl }
        <<< runUserApiClient { baseUrl: userApiBaseUrl }
        <<< Run.expand
      program = runApplicationPorts
        $ RunExcept.runExcept
        $ getCheapestShippingRate (UserId "user-123") (Weight 1000)
    result <- runParallel interpretApis program
    liftEffect $ log $ show result

getEnv :: String -> String -> Effect String
getEnv name defaultValue = fromMaybe defaultValue <$> lookupEnv name
