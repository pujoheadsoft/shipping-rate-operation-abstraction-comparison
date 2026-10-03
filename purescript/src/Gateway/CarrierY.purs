module Gateway.CarrierY
  ( CarrierYRateRequest(..)
  , CarrierYRateResponse(..)
  ) where

import Prelude

newtype CarrierYRateRequest = CarrierYRateRequest
  { postalCode :: String
  , weight :: Int
  }

derive newtype instance Eq CarrierYRateRequest
derive newtype instance Show CarrierYRateRequest

newtype CarrierYRateResponse = CarrierYRateResponse
  { price :: Int
  , serviceName :: String
  }

derive newtype instance Eq CarrierYRateResponse
derive newtype instance Show CarrierYRateResponse
