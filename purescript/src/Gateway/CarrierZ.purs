module Gateway.CarrierZ
  ( CarrierZRateRequest(..)
  , CarrierZRateResponse(..)
  ) where

import Prelude

newtype CarrierZRateRequest = CarrierZRateRequest
  { postalCode :: String
  , weight :: Int
  }

derive newtype instance Eq CarrierZRateRequest
derive newtype instance Show CarrierZRateRequest

newtype CarrierZRateResponse = CarrierZRateResponse
  { amount :: Int
  , serviceCode :: String
  }

derive newtype instance Eq CarrierZRateResponse
derive newtype instance Show CarrierZRateResponse
