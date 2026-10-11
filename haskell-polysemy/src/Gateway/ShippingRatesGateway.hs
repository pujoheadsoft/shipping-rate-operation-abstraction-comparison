module Gateway.ShippingRatesGateway
  ( fetchShippingRates
  , runShippingRatePort
  ) where

import           Data.Foldable             (traverse_)
import           Data.List.NonEmpty        (NonEmpty (..))
import           Domain.Shipment
import           Domain.ShippingRate
import           Domain.ShippingRates
import qualified Gateway.CarrierXApiClient as X
import qualified Gateway.CarrierYApiClient as Y
import qualified Gateway.CarrierZApiClient as Z
import           Polysemy                  (Members, Sem, interpret)
import           Polysemy.Async            (Async, async, await, cancel)
import           Polysemy.Error            (Error, runError, throw)
import           Polysemy.Resource         (Resource, bracket)
import           UseCase.ShippingRatePort  (FetchShippingRatesError (..),
                                            ShippingRatePort (..))

fetchShippingRates
  :: Members
       '[ X.CarrierXApiClient
        , Y.CarrierYApiClient
        , Z.CarrierZApiClient
        , Error FetchShippingRatesError
        , Async
        , Resource
        ] r
  => Shipment
  -> Sem r ShippingRates
fetchShippingRates shipment = do
  results <- sequenceConcurrentlyScoped
    [ fetchCarrierXRate shipment
    , fetchCarrierYRate shipment
    , fetchCarrierZRate shipment
    ]
  case results of
    [Just x, Just y, Just z] ->
      pure $ ShippingRates (x :| [y, z])
    _ -> throw FetchShippingRatesFailed

fetchCarrierXRate
  :: Members '[X.CarrierXApiClient, Error FetchShippingRatesError] r
  => Shipment
  -> Sem r ShippingRate
fetchCarrierXRate shipment = do
  response <- X.fetchRateX request
    >>= either (const $ throw FetchShippingRatesFailed) pure
  pure $ ShippingRate "CarrierX" (X.amount response)
  where
    request = X.CarrierXRateRequest
      (destinationPostalCode shipment)
      (weight shipment)

fetchCarrierYRate
  :: Members '[Y.CarrierYApiClient, Error FetchShippingRatesError] r
  => Shipment
  -> Sem r ShippingRate
fetchCarrierYRate shipment = do
  response <- Y.fetchRateY request
    >>= either (const $ throw FetchShippingRatesFailed) pure
  pure $ ShippingRate "CarrierY" (Y.price response)
  where
    request = Y.CarrierYRateRequest
      (destinationPostalCode shipment)
      (weight shipment)

fetchCarrierZRate
  :: Members '[Z.CarrierZApiClient, Error FetchShippingRatesError] r
  => Shipment
  -> Sem r ShippingRate
fetchCarrierZRate shipment = do
  response <- Z.fetchRateZ request
    >>= either (const $ throw FetchShippingRatesFailed) pure
  pure $ ShippingRate "CarrierZ" (Z.amount response)
  where
    request = Z.CarrierZRateRequest
      (destinationPostalCode shipment)
      (weight shipment)

sequenceConcurrentlyScoped
  :: Members '[Async, Resource] r
  => [Sem r a]
  -> Sem r [Maybe a]
sequenceConcurrentlyScoped actions =
  bracket
    (traverse async actions)
    (traverse_ cancel)
    (traverse await)

runShippingRatePort
  :: Members
       '[ X.CarrierXApiClient
        , Y.CarrierYApiClient
        , Z.CarrierZApiClient
        , Async
        , Resource
        ] r
  => Sem (ShippingRatePort ': r) a
  -> Sem r a
runShippingRatePort = interpret \case
  FetchShippingRates shipment ->
    runError @FetchShippingRatesError $ fetchShippingRates shipment
