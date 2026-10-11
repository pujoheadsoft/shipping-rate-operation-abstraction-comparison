module Test.Support.RunCarriers
  ( CarrierClients
  , runCarriersWith
  ) where

import Prelude

import Data.Either (Either)
import Effect.Aff (Aff)
import Gateway.CarrierXApiClient as X
import Gateway.CarrierYApiClient as Y
import Gateway.CarrierZApiClient as Z
import Gateway.ShippingRatesGateway (CARRIER_API_CLIENTS)
import Run (Run)
import Run as Run

type CarrierClients =
  { carrierX :: X.CarrierXRateRequest -> Aff (Either X.CarrierXApiError X.CarrierXRateResponse)
  , carrierY :: Y.CarrierYRateRequest -> Aff (Either Y.CarrierYApiError Y.CarrierYRateResponse)
  , carrierZ :: Z.CarrierZRateRequest -> Aff (Either Z.CarrierZApiError Z.CarrierZRateResponse)
  }

runCarriersWith :: CarrierClients -> Run (CARRIER_API_CLIENTS ()) ~> Aff
runCarriersWith clients = Run.interpret handler
  where
  handler :: Run.VariantF (CARRIER_API_CLIENTS ()) ~> Aff
  handler = Run.match
    { carrierXApiClient: case _ of
        X.FetchRate request next -> next <$> clients.carrierX request
    , carrierYApiClient: case _ of
        Y.FetchRate request next -> next <$> clients.carrierY request
    , carrierZApiClient: case _ of
        Z.FetchRate request next -> next <$> clients.carrierZ request
    }
