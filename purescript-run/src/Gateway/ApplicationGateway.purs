module Gateway.ApplicationGateway
  ( API_CLIENTS
  , runApplicationPorts
  ) where

import Prelude
import Gateway.PostalCodeGateway (fetchPostalCode)
import Gateway.ShippingRatesGateway (CARRIER_API_CLIENTS, fetchShippingRates)
import Gateway.UserApiClient as UserApi
import Run as Run
import Run.Parallel (ParallelRun, liftParallel, liftRun)
import UseCase.PostalCodePort (POSTAL_CODE_PORT, PostalCodePortF(..))
import UseCase.ShippingRatePort
  ( SHIPPING_RATE_PORT
  , ShippingRatePortF(..)
  )

type API_CLIENTS r =
  ( userApiClient :: UserApi.USER_API_CLIENT
  | CARRIER_API_CLIENTS r
  )

runApplicationPorts
  :: forall r
   . Run.Run
       ( postalCodePort :: POSTAL_CODE_PORT
       , shippingRatePort :: SHIPPING_RATE_PORT
       )
  ~> ParallelRun (API_CLIENTS r)
runApplicationPorts = Run.run $ Run.match
  { postalCodePort: case _ of
      FetchPostalCodeByUserId userId next ->
        next <$> liftRun (fetchPostalCode userId)
  , shippingRatePort: case _ of
      FetchShippingRates shipment next ->
        next <$> liftParallel (fetchShippingRates shipment)
  }
