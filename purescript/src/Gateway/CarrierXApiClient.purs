module Gateway.CarrierXApiClient
  ( CarrierXApiClient
  , CarrierXApiError(..)
  , CarrierXRateRequest
  , CarrierXRateResponse
  ) where

import Data.Either (Either)
import Effect.Aff (Aff)

type CarrierXRateRequest =
  { destination :: String
  , weightGrams :: Int
  }

type CarrierXRateResponse =
  { amount :: Int
  , serviceCode :: String
  }

data CarrierXApiError
  = CarrierXApiRequestFailed

type CarrierXApiClient =
  { fetchRate
      :: CarrierXRateRequest
      -> Aff (Either CarrierXApiError CarrierXRateResponse)
  }
