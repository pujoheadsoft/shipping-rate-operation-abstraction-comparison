module Gateway.ShippingRatesGateway
  ( Dependencies
  , createShippingRatePort
  , fetchShippingRates
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT(..), runExceptT)
import Control.Monad.Reader.Trans (ReaderT, asks, lift, runReaderT)
import Control.Parallel (parSequence)
import Data.Array.NonEmpty as NonEmptyArray
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Effect.Aff (Aff)
import Gateway.CarrierXApiClient
  ( CarrierXApiClient
  , CarrierXRateRequest
  , CarrierXRateResponse
  )
import Gateway.CarrierYApiClient
  ( CarrierYApiClient
  , CarrierYRateRequest
  , CarrierYRateResponse
  )
import Gateway.CarrierZApiClient
  ( CarrierZApiClient
  , CarrierZRateRequest
  , CarrierZRateResponse
  )
import UseCase.ShippingRatePort (FetchShippingRatesError(..), ShippingRatePort)

type Dependencies =
  { carrierXApiClient :: CarrierXApiClient
  , carrierYApiClient :: CarrierYApiClient
  , carrierZApiClient :: CarrierZApiClient
  }

fetchShippingRates
  :: Shipment
  -> ReaderT Dependencies
       (ExceptT FetchShippingRatesError Aff)
       ShippingRates
fetchShippingRates shipment =
  ShippingRates <$> parSequence
    (NonEmptyArray.cons'
      (fetchCarrierXRate shipment)
      [ fetchCarrierYRate shipment
      , fetchCarrierZRate shipment 
      ])

fetchCarrierXRate
  :: Shipment
  -> ReaderT Dependencies
       (ExceptT FetchShippingRatesError Aff)
       ShippingRate
fetchCarrierXRate =
  toCarrierXRateRequest
    >>> callCarrier _.carrierXApiClient
    >>> map carrierXResponseToShippingRate

fetchCarrierYRate
  :: Shipment
  -> ReaderT Dependencies
       (ExceptT FetchShippingRatesError Aff)
       ShippingRate
fetchCarrierYRate =
  toCarrierYRateRequest
    >>> callCarrier _.carrierYApiClient
    >>> map carrierYResponseToShippingRate

fetchCarrierZRate
  :: Shipment
  -> ReaderT Dependencies
       (ExceptT FetchShippingRatesError Aff)
       ShippingRate
fetchCarrierZRate =
  toCarrierZRateRequest
    >>> callCarrier _.carrierZApiClient
    >>> map carrierZResponseToShippingRate

callCarrier
  :: forall request response error client
   . (Dependencies -> { fetchRate :: request -> Aff (Either error response) | client })
  -> request
  -> ReaderT Dependencies
       (ExceptT FetchShippingRatesError Aff)
       response
callCarrier selectClient request = do
  client <- asks selectClient
  lift $ liftCarrier $ client.fetchRate request

liftCarrier
  :: forall error a
   . Aff (Either error a)
  -> ExceptT FetchShippingRatesError Aff a
liftCarrier action =
  ExceptT $ lmap (const FetchShippingRatesFailed) <$> action

toCarrierXRateRequest :: Shipment -> CarrierXRateRequest
toCarrierXRateRequest (Shipment shipment) =
  { destination: shipment.destinationPostalCode
  , weightGrams: shipment.weight
  }

toCarrierYRateRequest :: Shipment -> CarrierYRateRequest
toCarrierYRateRequest (Shipment shipment) =
  { postalCode: shipment.destinationPostalCode
  , weight: shipment.weight
  }

toCarrierZRateRequest :: Shipment -> CarrierZRateRequest
toCarrierZRateRequest (Shipment shipment) =
  { postalCode: shipment.destinationPostalCode
  , weight: shipment.weight
  }

carrierXResponseToShippingRate :: CarrierXRateResponse -> ShippingRate
carrierXResponseToShippingRate response = ShippingRate
  { carrier: response.serviceCode
  , amount: response.amount
  }

carrierYResponseToShippingRate :: CarrierYRateResponse -> ShippingRate
carrierYResponseToShippingRate response = ShippingRate
  { carrier: response.serviceName
  , amount: response.price
  }

carrierZResponseToShippingRate :: CarrierZRateResponse -> ShippingRate
carrierZResponseToShippingRate response = ShippingRate
  { carrier: response.serviceCode
  , amount: response.amount
  }

createShippingRatePort :: Dependencies -> ShippingRatePort
createShippingRatePort dependencies =
  { fetchShippingRates: \shipment ->
      runExceptT $ runReaderT (fetchShippingRates shipment) dependencies
  }
