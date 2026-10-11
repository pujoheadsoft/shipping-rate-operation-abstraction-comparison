module UseCase.ShippingRatePort
  ( FetchShippingRatesError(..)
  , ShippingRatePortF(..)
  , SHIPPING_RATE_PORT
  , fetchShippingRates
  ) where

import Prelude
import Data.Either (Either)
import Domain.Shipment (Shipment)
import Domain.ShippingRates (ShippingRates)
import Run (Run, lift)
import Type.Proxy (Proxy(..))

data FetchShippingRatesError = FetchShippingRatesFailed

derive instance Eq FetchShippingRatesError
instance Show FetchShippingRatesError where
  show FetchShippingRatesFailed = "FetchShippingRatesFailed"

data ShippingRatePortF a = FetchShippingRates Shipment (Either FetchShippingRatesError ShippingRates -> a)

derive instance Functor ShippingRatePortF
type SHIPPING_RATE_PORT = ShippingRatePortF

fetchShippingRates
  :: forall r
   . Shipment
  -> Run (shippingRatePort :: SHIPPING_RATE_PORT | r) (Either FetchShippingRatesError ShippingRates)
fetchShippingRates shipment = lift (Proxy :: Proxy "shippingRatePort") (FetchShippingRates shipment identity)
