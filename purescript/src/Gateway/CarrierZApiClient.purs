module Gateway.CarrierZApiClient
  ( CarrierZApiClient
  , CarrierZApiError(..)
  , CarrierZRateRequest
  , CarrierZRateResponse
  ) where

import Data.Either (Either)
import Effect.Aff (Aff)

type CarrierZRateRequest =
  { postalCode :: String
  , weight :: Int
  }

type CarrierZRateResponse =
  { amount :: Int
  , serviceCode :: String
  }

data CarrierZApiError
  = CarrierZApiRequestFailed

type CarrierZApiClient =
  { fetchRate
      :: CarrierZRateRequest
      -> Aff (Either CarrierZApiError CarrierZRateResponse)
  }
