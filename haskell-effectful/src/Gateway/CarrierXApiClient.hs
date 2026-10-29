module Gateway.CarrierXApiClient where

import           Data.Aeson (FromJSON)
import           Effectful
import           Effectful.Dispatch.Dynamic (send)
import           GHC.Generics (Generic)

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

data CarrierXApiClient :: Effect where
  FetchRateX
    :: CarrierXRateRequest
    -> CarrierXApiClient m (Either CarrierXApiError CarrierXRateResponse)

type instance DispatchOf CarrierXApiClient = Dynamic

fetchRateX
  :: CarrierXApiClient :> es
  => CarrierXRateRequest
  -> Eff es (Either CarrierXApiError CarrierXRateResponse)
fetchRateX request = send $ FetchRateX request
