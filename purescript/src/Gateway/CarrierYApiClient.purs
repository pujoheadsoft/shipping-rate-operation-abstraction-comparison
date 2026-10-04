module Gateway.CarrierYApiClient
  ( CarrierYApiClient
  , CarrierYApiError(..)
  , CarrierYRateRequest
  , CarrierYRateResponse
  ) where

import Data.Either (Either)
import Effect.Aff (Aff)

type CarrierYRateRequest =
  { postalCode :: String
  , weight :: Int
  }

type CarrierYRateResponse =
  { price :: Int
  , serviceName :: String
  }

data CarrierYApiError
  = CarrierYApiRequestFailed

type CarrierYApiClient =
  { fetchRate
      :: CarrierYRateRequest
      -> Aff (Either CarrierYApiError CarrierYRateResponse)
  }
