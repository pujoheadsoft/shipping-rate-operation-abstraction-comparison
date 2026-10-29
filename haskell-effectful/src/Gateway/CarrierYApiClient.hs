module Gateway.CarrierYApiClient where

import           Data.Aeson (FromJSON)
import           Effectful
import           Effectful.Dispatch.Dynamic (send)
import           GHC.Generics (Generic)

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

data CarrierYApiClient :: Effect where
  FetchRateY
    :: CarrierYRateRequest
    -> CarrierYApiClient m (Either CarrierYApiError CarrierYRateResponse)

type instance DispatchOf CarrierYApiClient = Dynamic

fetchRateY
  :: CarrierYApiClient :> es
  => CarrierYRateRequest
  -> Eff es (Either CarrierYApiError CarrierYRateResponse)
fetchRateY request = send $ FetchRateY request
