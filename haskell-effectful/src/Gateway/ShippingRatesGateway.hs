module Gateway.ShippingRatesGateway
  ( fetchShippingRates
  , runShippingRatePort
  ) where

import           Data.List.NonEmpty         (NonEmpty (..))
import           Domain.PostalCode          (PostalCode (..))
import           Domain.Shipment
import           Domain.ShippingRate
import           Domain.ShippingRates
import           Domain.Weight              (Weight (..))
import           Effectful
import           Effectful.Concurrent.Async (Concurrent, concurrently)
import           Effectful.Dispatch.Dynamic (interpret)
import           Effectful.Error.Static     (Error, runErrorNoCallStack,
                                             throwError)
import qualified Gateway.CarrierXApiClient  as X
import qualified Gateway.CarrierYApiClient  as Y
import qualified Gateway.CarrierZApiClient  as Z
import           UseCase.ShippingRatePort   (FetchShippingRatesError (..),
                                             ShippingRatePort (..))

fetchShippingRates
  :: ( Concurrent :> es
     , Error FetchShippingRatesError :> es
     , X.CarrierXApiClient :> es
     , Y.CarrierYApiClient :> es
     , Z.CarrierZApiClient :> es
     )
  => Shipment
  -> Eff es ShippingRates
fetchShippingRates shipment = do
  (x, y, z) <- parallel3
    (fetchCarrierXRate shipment)
    (fetchCarrierYRate shipment)
    (fetchCarrierZRate shipment)
  pure $ ShippingRates (x :| [y, z])

fetchCarrierXRate
  :: ( X.CarrierXApiClient :> es
     , Error FetchShippingRatesError :> es
     )
  => Shipment
  -> Eff es ShippingRate
fetchCarrierXRate shipment = do
  response <- X.fetchRateX request
    >>= either (const $ throwError FetchShippingRatesFailed) pure
  pure $ ShippingRate "CarrierX" (X.amount response)
  where
    request = X.CarrierXRateRequest postalCode weightInGrams
    PostalCode postalCode = destinationPostalCode shipment
    Weight weightInGrams = weight shipment

fetchCarrierYRate
  :: ( Y.CarrierYApiClient :> es
     , Error FetchShippingRatesError :> es
     )
  => Shipment
  -> Eff es ShippingRate
fetchCarrierYRate shipment = do
  response <- Y.fetchRateY request
    >>= either (const $ throwError FetchShippingRatesFailed) pure
  pure $ ShippingRate "CarrierY" (Y.price response)
  where
    request = Y.CarrierYRateRequest postalCode weightInGrams
    PostalCode postalCode = destinationPostalCode shipment
    Weight weightInGrams = weight shipment

fetchCarrierZRate
  :: ( Z.CarrierZApiClient :> es
     , Error FetchShippingRatesError :> es
     )
  => Shipment
  -> Eff es ShippingRate
fetchCarrierZRate shipment = do
  response <- Z.fetchRateZ request
    >>= either (const $ throwError FetchShippingRatesFailed) pure
  pure $ ShippingRate "CarrierZ" (Z.amount response)
  where
    request = Z.CarrierZRateRequest postalCode weightInGrams
    PostalCode postalCode = destinationPostalCode shipment
    Weight weightInGrams = weight shipment

parallel3
  :: Concurrent :> es
  => Eff es a
  -> Eff es b
  -> Eff es c
  -> Eff es (a, b, c)
parallel3 a b c = do
  (x, (y, z)) <- concurrently a $ concurrently b c
  pure (x, y, z)

runShippingRatePort
  :: ( Concurrent :> es
     , X.CarrierXApiClient :> es
     , Y.CarrierYApiClient :> es
     , Z.CarrierZApiClient :> es
     )
  => Eff (ShippingRatePort : es) a
  -> Eff es a
runShippingRatePort = interpret $ \_ -> \case
  FetchShippingRates shipment ->
    runErrorNoCallStack @FetchShippingRatesError
      $ fetchShippingRates shipment
