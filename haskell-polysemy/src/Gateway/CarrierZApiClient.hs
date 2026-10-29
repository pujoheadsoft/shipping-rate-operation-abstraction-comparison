module Gateway.CarrierZApiClient where

import           Data.Aeson (FromJSON)
import           GHC.Generics (Generic)
import           Polysemy (makeSem)

data CarrierZRateRequest = CarrierZRateRequest
  { postalCode :: String
  , weight     :: Int
  } deriving (Eq, Show)

data CarrierZRateResponse = CarrierZRateResponse
  { amount      :: Int
  , serviceCode :: String
  } deriving (Eq, Generic, Show)

instance FromJSON CarrierZRateResponse

data CarrierZApiError = CarrierZApiOperationFailed deriving (Eq, Show)

data CarrierZApiClient m a where
  FetchRateZ
    :: CarrierZRateRequest
    -> CarrierZApiClient m (Either CarrierZApiError CarrierZRateResponse)

makeSem ''CarrierZApiClient
