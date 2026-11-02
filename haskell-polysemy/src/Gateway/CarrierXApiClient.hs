module Gateway.CarrierXApiClient where

import           Polysemy (makeSem)

data CarrierXRateRequest = CarrierXRateRequest
  { destination :: String
  , weightGrams :: Int
  } deriving (Eq, Show)

data CarrierXRateResponse = CarrierXRateResponse
  { amount      :: Int
  , serviceCode :: String
  } deriving (Eq, Show)

data CarrierXApiError = CarrierXApiOperationFailed deriving (Eq, Show)

data CarrierXApiClient m a where
  FetchRateX
    :: CarrierXRateRequest
    -> CarrierXApiClient m (Either CarrierXApiError CarrierXRateResponse)

makeSem ''CarrierXApiClient
