module Gateway.CarrierYApiClient where

import Prelude
import Data.Either (Either)
import Run (Run, lift)
import Type.Proxy (Proxy(..))

type CarrierYRateRequest = { postalCode :: String, weight :: Int }
type CarrierYRateResponse = { price :: Int, serviceName :: String }
data CarrierYApiError = CarrierYApiOperationFailed

derive instance Eq CarrierYApiError

data CarrierYApiClientF a = FetchRate CarrierYRateRequest (Either CarrierYApiError CarrierYRateResponse -> a)

derive instance Functor CarrierYApiClientF
type CARRIER_Y_API_CLIENT = CarrierYApiClientF

_carrierYApiClient :: Proxy "carrierYApiClient"
_carrierYApiClient = Proxy

fetchRate
  :: forall r
   . CarrierYRateRequest
  -> Run (carrierYApiClient :: CARRIER_Y_API_CLIENT | r) (Either CarrierYApiError CarrierYRateResponse)
fetchRate request = lift _carrierYApiClient (FetchRate request identity)
