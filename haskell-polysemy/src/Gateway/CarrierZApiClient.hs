module Gateway.CarrierZApiClient where

import           Polysemy (makeSem)

data CarrierZRateRequest = CarrierZRateRequest
  { postalCode :: String
  , weight     :: Int
  } deriving (Eq, Show)

data CarrierZRateResponse = CarrierZRateResponse
  { amount      :: Int
  , serviceCode :: String
  } deriving (Eq, Show)

data CarrierZApiError = CarrierZApiOperationFailed deriving (Eq, Show)

data CarrierZApiClient m a where
  FetchRateZ
    :: CarrierZRateRequest
    -> CarrierZApiClient m (Either CarrierZApiError CarrierZRateResponse)

makeSem ''CarrierZApiClient
