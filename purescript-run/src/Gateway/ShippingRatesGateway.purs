module Gateway.ShippingRatesGateway
  ( CARRIER_API_CLIENTS
  , fetchShippingRates
  , runShippingRatePort
  ) where

import Prelude
import Control.Applicative.Free (FreeAp)
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Data.NonEmpty (NonEmpty, (:|))
import Data.Traversable (sequence)
import Domain.Shipment (Shipment(..))
import Domain.PostalCode (PostalCode(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Domain.Weight (Weight(..))
import Gateway.CarrierXApiClient as X
import Gateway.CarrierYApiClient as Y
import Gateway.CarrierZApiClient as Z
import Run (Run)
import Run as Run
import Run.Parallel (ParallelRun, liftParallel, parallelSequence)
import UseCase.ShippingRatePort (FetchShippingRatesError(..), ShippingRatePortF(..), SHIPPING_RATE_PORT)

type CARRIER_API_CLIENTS r =
  ( carrierXApiClient :: X.CARRIER_X_API_CLIENT
  , carrierYApiClient :: Y.CARRIER_Y_API_CLIENT
  , carrierZApiClient :: Z.CARRIER_Z_API_CLIENT
  | r
  )

runShippingRatePort
  :: forall r
   . Run (shippingRatePort :: SHIPPING_RATE_PORT | ())
  ~> ParallelRun (CARRIER_API_CLIENTS r)
runShippingRatePort = Run.run $ Run.match
  { shippingRatePort: case _ of
      FetchShippingRates shipment next ->
        next <$> liftParallel (fetchShippingRates shipment)
  }

fetchShippingRates
  :: forall r
   . Shipment
  -> FreeAp
       (Run (CARRIER_API_CLIENTS r))
       (Either FetchShippingRatesError ShippingRates)
fetchShippingRates shipment =
  let
    fetches = fetchCarrierXRate shipment :|
      [ fetchCarrierYRate shipment
      , fetchCarrierZRate shipment
      ]
  in parallelSequence fetches
    # map sequence
    # map (map toShippingRates)

fetchCarrierXRate
  :: forall r
   . Shipment
  -> Run (carrierXApiClient :: X.CARRIER_X_API_CLIENT | r) (Either FetchShippingRatesError ShippingRate)
fetchCarrierXRate shipment = X.fetchRate (toCarrierXRateRequest shipment)
  # map (lmap (const FetchShippingRatesFailed) >>> map toShippingRateX)

fetchCarrierYRate
  :: forall r
   . Shipment
  -> Run (carrierYApiClient :: Y.CARRIER_Y_API_CLIENT | r) (Either FetchShippingRatesError ShippingRate)
fetchCarrierYRate shipment = Y.fetchRate (toCarrierYRateRequest shipment)
  # map (lmap (const FetchShippingRatesFailed) >>> map toShippingRateY)

fetchCarrierZRate
  :: forall r
   . Shipment
  -> Run (carrierZApiClient :: Z.CARRIER_Z_API_CLIENT | r) (Either FetchShippingRatesError ShippingRate)
fetchCarrierZRate shipment = Z.fetchRate (toCarrierZRateRequest shipment)
  # map (lmap (const FetchShippingRatesFailed) >>> map toShippingRateZ)

toCarrierXRateRequest :: Shipment -> X.CarrierXRateRequest
toCarrierXRateRequest (Shipment { destinationPostalCode: PostalCode postalCode, weight: Weight weight }) =
  { destination: postalCode, weightGrams: weight }

toCarrierYRateRequest :: Shipment -> Y.CarrierYRateRequest
toCarrierYRateRequest (Shipment { destinationPostalCode: PostalCode postalCode, weight: Weight weight }) =
  { postalCode, weight }

toCarrierZRateRequest :: Shipment -> Z.CarrierZRateRequest
toCarrierZRateRequest (Shipment { destinationPostalCode: PostalCode postalCode, weight: Weight weight }) =
  { postalCode, weight }

toShippingRates :: NonEmpty Array ShippingRate -> ShippingRates
toShippingRates (head :| tail) = ShippingRates { head, tail }

toShippingRateX :: X.CarrierXRateResponse -> ShippingRate
toShippingRateX response = ShippingRate { carrier: "CarrierX", amount: response.amount }

toShippingRateY :: Y.CarrierYRateResponse -> ShippingRate
toShippingRateY response = ShippingRate { carrier: "CarrierY", amount: response.price }

toShippingRateZ :: Z.CarrierZRateResponse -> ShippingRate
toShippingRateZ response = ShippingRate { carrier: "CarrierZ", amount: response.amount }
