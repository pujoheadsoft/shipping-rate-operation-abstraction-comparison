module Gateway.CarrierYApiClient where

import           Polysemy (makeSem)

data CarrierYRateRequest = CarrierYRateRequest
  { postalCode :: String
  , weight     :: Int
  } deriving (Eq, Show)

data CarrierYRateResponse = CarrierYRateResponse
  { price       :: Int
  , serviceName :: String
  } deriving (Eq, Show)

data CarrierYApiError = CarrierYApiOperationFailed deriving (Eq, Show)

data CarrierYApiClient m a where
  FetchRateY
    :: CarrierYRateRequest
    -> CarrierYApiClient m (Either CarrierYApiError CarrierYRateResponse)

makeSem ''CarrierYApiClient
