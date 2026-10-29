module Gateway.CarrierXApiClient where

import           Data.Aeson (FromJSON)
import           GHC.Generics (Generic)
import           Polysemy (makeSem)

data CarrierXRateRequest = CarrierXRateRequest
  { destination :: String
  , weightGrams :: Int
  } deriving (Eq, Show)

data CarrierXRateResponse = CarrierXRateResponse
  { amount      :: Int
  , serviceCode :: String
  } deriving (Eq, Generic, Show)

instance FromJSON CarrierXRateResponse

data CarrierXApiError = CarrierXApiOperationFailed deriving (Eq, Show)

data CarrierXApiClient m a where
  FetchRateX
    :: CarrierXRateRequest
    -> CarrierXApiClient m (Either CarrierXApiError CarrierXRateResponse)

makeSem ''CarrierXApiClient
