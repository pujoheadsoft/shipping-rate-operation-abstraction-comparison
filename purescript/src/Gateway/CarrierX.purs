module Gateway.CarrierX
  ( CarrierXRateRequest(..)
  , CarrierXRateResponse(..)
  ) where

import Prelude

newtype CarrierXRateRequest = CarrierXRateRequest
  { destination :: String
  , weightGrams :: Int
  }

derive newtype instance Eq CarrierXRateRequest
derive newtype instance Show CarrierXRateRequest

newtype CarrierXRateResponse = CarrierXRateResponse
  { amount :: Int
  , serviceCode :: String
  }

derive newtype instance Eq CarrierXRateResponse
derive newtype instance Show CarrierXRateResponse
