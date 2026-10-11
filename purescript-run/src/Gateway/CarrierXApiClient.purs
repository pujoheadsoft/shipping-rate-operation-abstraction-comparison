module Gateway.CarrierXApiClient where

import Prelude
import Data.Either (Either)
import Run (Run, lift)
import Type.Proxy (Proxy(..))

type CarrierXRateRequest = { destination :: String, weightGrams :: Int }
type CarrierXRateResponse = { amount :: Int, serviceCode :: String }
data CarrierXApiError = CarrierXApiOperationFailed

derive instance Eq CarrierXApiError

data CarrierXApiClientF a = FetchRate CarrierXRateRequest (Either CarrierXApiError CarrierXRateResponse -> a)

derive instance Functor CarrierXApiClientF
type CARRIER_X_API_CLIENT = CarrierXApiClientF

_carrierXApiClient :: Proxy "carrierXApiClient"
_carrierXApiClient = Proxy

fetchRate
  :: forall r
   . CarrierXRateRequest
  -> Run (carrierXApiClient :: CARRIER_X_API_CLIENT | r) (Either CarrierXApiError CarrierXRateResponse)
fetchRate request = lift _carrierXApiClient (FetchRate request identity)
