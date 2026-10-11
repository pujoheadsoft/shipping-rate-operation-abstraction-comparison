module Gateway.CarrierZApiClient where

import           Effectful
import           Effectful.Dispatch.Dynamic (send)

data CarrierZRateRequest = CarrierZRateRequest
  { postalCode :: String
  , weight     :: Int
  } deriving (Eq, Show)

data CarrierZRateResponse = CarrierZRateResponse
  { amount      :: Int
  , serviceCode :: String
  } deriving (Eq, Show)

data CarrierZApiError = CarrierZApiOperationFailed deriving (Eq, Show)

data CarrierZApiClient :: Effect where
  FetchRateZ
    :: CarrierZRateRequest
    -> CarrierZApiClient m (Either CarrierZApiError CarrierZRateResponse)

type instance DispatchOf CarrierZApiClient = Dynamic

fetchRateZ
  :: CarrierZApiClient :> es
  => CarrierZRateRequest
  -> Eff es (Either CarrierZApiError CarrierZRateResponse)
fetchRateZ request = send $ FetchRateZ request
