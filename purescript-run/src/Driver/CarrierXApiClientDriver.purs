module Driver.CarrierXApiClientDriver (CarrierXApiEnvironment, runCarrierXApiClient) where

import Prelude
import Data.Bifunctor (lmap)
import Driver.Error (DriverError)
import Driver.HttpClient (decodeJson, fetchPost, toDriverResult)
import Gateway.CarrierXApiClient (CarrierXApiError(..), CarrierXRateRequest, CarrierXRateResponse)
import Gateway.CarrierXApiClient as CarrierXApiClient
import Run (AFF, Run)
import Run as Run
import Run.Except as RunExcept
import Run.Reader as RunReader
import Type.Row (type (+))
import Yoga.JSON (writeJSON)

type CarrierXApiEnvironment = { baseUrl :: String }

runCarrierXApiClient
  :: forall r
   . CarrierXApiEnvironment
  -> Run (AFF + (carrierXApiClient :: CarrierXApiClient.CARRIER_X_API_CLIENT | r))
  ~> Run (AFF + r)
runCarrierXApiClient environment run = Run.interpret
  (Run.on
    CarrierXApiClient._carrierXApiClient
    (carrierXApiClientHandler environment)
    Run.send)
  run

carrierXApiClientHandler
  :: forall r
   . CarrierXApiEnvironment
  -> CarrierXApiClient.CarrierXApiClientF
  ~> Run (AFF + r)
carrierXApiClientHandler environment = case _ of
  CarrierXApiClient.FetchRate request next -> do
    result <- performFetchRate request
      # RunReader.runReader environment
      # RunExcept.runExcept
    pure $ next $ lmap (const CarrierXApiOperationFailed) result

performFetchRate
  :: forall r
   . CarrierXRateRequest
  -> Run
       ( RunReader.READER CarrierXApiEnvironment
       + RunExcept.EXCEPT DriverError
       + AFF
       + r
       )
       CarrierXRateResponse
performFetchRate request = do
  environment <- RunReader.ask
  body <- toDriverResult $ fetchPost (environment.baseUrl <> "/shipping-rates") (writeJSON request)
  decodeJson body
