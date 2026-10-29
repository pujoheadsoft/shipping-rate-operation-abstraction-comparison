module Gateway.CarrierYApiClient where

import           Data.Aeson (FromJSON)
import           GHC.Generics (Generic)
import           Polysemy (makeSem)

data CarrierYRateRequest = CarrierYRateRequest
  { postalCode :: String
  , weight     :: Int
  } deriving (Eq, Show)

data CarrierYRateResponse = CarrierYRateResponse
  { price       :: Int
  , serviceName :: String
  } deriving (Eq, Generic, Show)

instance FromJSON CarrierYRateResponse

data CarrierYApiError = CarrierYApiOperationFailed deriving (Eq, Show)

data CarrierYApiClient m a where
  FetchRateY
    :: CarrierYRateRequest
    -> CarrierYApiClient m (Either CarrierYApiError CarrierYRateResponse)

makeSem ''CarrierYApiClient
