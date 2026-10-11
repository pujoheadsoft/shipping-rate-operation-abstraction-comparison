module Driver.CarrierYApiClientDriver (CarrierYApiEnvironment, runCarrierYApiClient) where

import Prelude
import Data.Bifunctor (lmap)
import Driver.Error (DriverError)
import Driver.HttpClient (decodeJson, fetchPost, toDriverResult)
import Gateway.CarrierYApiClient (CarrierYApiError(..), CarrierYRateRequest, CarrierYRateResponse)
import Gateway.CarrierYApiClient as CarrierYApiClient
import Run (AFF, Run)
import Run as Run
import Run.Except as RunExcept
import Run.Reader as RunReader
import Type.Row (type (+))
import Yoga.JSON (writeJSON)

type CarrierYApiEnvironment = { baseUrl :: String }

runCarrierYApiClient
  :: forall r
   . CarrierYApiEnvironment
  -> Run (AFF + (carrierYApiClient :: CarrierYApiClient.CARRIER_Y_API_CLIENT | r))
  ~> Run (AFF + r)
runCarrierYApiClient environment run = Run.interpret
  (Run.on
    CarrierYApiClient._carrierYApiClient
    (carrierYApiClientHandler environment)
    Run.send)
  run

carrierYApiClientHandler
  :: forall r
   . CarrierYApiEnvironment
  -> CarrierYApiClient.CarrierYApiClientF
  ~> Run (AFF + r)
carrierYApiClientHandler environment = case _ of
  CarrierYApiClient.FetchRate request next -> do
    result <- performFetchRate request
      # RunReader.runReader environment
      # RunExcept.runExcept
    pure $ next $ lmap (const CarrierYApiOperationFailed) result

performFetchRate
  :: forall r
   . CarrierYRateRequest
  -> Run
       ( RunReader.READER CarrierYApiEnvironment
       + RunExcept.EXCEPT DriverError
       + AFF
       + r
       )
       CarrierYRateResponse
performFetchRate request = do
  environment <- RunReader.ask
  body <- toDriverResult $ fetchPost (environment.baseUrl <> "/rates/quote") (writeJSON request)
  decodeJson body
