module Driver.CarrierZApiClientDriver (CarrierZApiEnvironment, runCarrierZApiClient) where

import Prelude
import Data.Bifunctor (lmap)
import Driver.Error (DriverError)
import Driver.HttpClient (decodeJson, fetchPost, toDriverResult)
import Gateway.CarrierZApiClient (CarrierZApiError(..), CarrierZRateRequest, CarrierZRateResponse)
import Gateway.CarrierZApiClient as CarrierZApiClient
import Run (AFF, Run)
import Run as Run
import Run.Except as RunExcept
import Run.Reader as RunReader
import Type.Row (type (+))
import Yoga.JSON (writeJSON)

type CarrierZApiEnvironment = { baseUrl :: String }

runCarrierZApiClient
  :: forall r
   . CarrierZApiEnvironment
  -> Run (AFF + (carrierZApiClient :: CarrierZApiClient.CARRIER_Z_API_CLIENT | r))
  ~> Run (AFF + r)
runCarrierZApiClient environment run = Run.interpret
  (Run.on
    CarrierZApiClient._carrierZApiClient
    (carrierZApiClientHandler environment)
    Run.send)
  run

carrierZApiClientHandler
  :: forall r
   . CarrierZApiEnvironment
  -> CarrierZApiClient.CarrierZApiClientF
  ~> Run (AFF + r)
carrierZApiClientHandler environment = case _ of
  CarrierZApiClient.FetchRate request next -> do
    result <- performFetchRate request
      # RunReader.runReader environment
      # RunExcept.runExcept
    pure $ next $ lmap (const CarrierZApiOperationFailed) result

performFetchRate
  :: forall r
   . CarrierZRateRequest
  -> Run
       ( RunReader.READER CarrierZApiEnvironment
       + RunExcept.EXCEPT DriverError
       + AFF
       + r
       )
       CarrierZRateResponse
performFetchRate request = do
  environment <- RunReader.ask
  body <- toDriverResult $ fetchPost (environment.baseUrl <> "/shipping/quote") (writeJSON request)
  decodeJson body
