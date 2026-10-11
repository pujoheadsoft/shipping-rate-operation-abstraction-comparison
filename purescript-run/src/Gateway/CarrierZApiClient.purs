module Gateway.CarrierZApiClient where

import Prelude
import Data.Either (Either)
import Run (Run, lift)
import Type.Proxy (Proxy(..))

type CarrierZRateRequest = { postalCode :: String, weight :: Int }
type CarrierZRateResponse = { amount :: Int, serviceCode :: String }
data CarrierZApiError = CarrierZApiOperationFailed

derive instance Eq CarrierZApiError

data CarrierZApiClientF a = FetchRate CarrierZRateRequest (Either CarrierZApiError CarrierZRateResponse -> a)

derive instance Functor CarrierZApiClientF
type CARRIER_Z_API_CLIENT = CarrierZApiClientF

_carrierZApiClient :: Proxy "carrierZApiClient"
_carrierZApiClient = Proxy

fetchRate
  :: forall r
   . CarrierZRateRequest
  -> Run (carrierZApiClient :: CARRIER_Z_API_CLIENT | r) (Either CarrierZApiError CarrierZRateResponse)
fetchRate request = lift _carrierZApiClient (FetchRate request identity)
