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
import Domain.PostalCode (PostalCode(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Domain.Weight (Weight(..))
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
toCarrierXRateRequest (Shipment { destinationPostalCode: PostalCode postalCode, weight: Weight weight }) =
  { destination: postalCode
  , weightGrams: weight
  }

toCarrierYRateRequest :: Shipment -> CarrierYRateRequest
toCarrierYRateRequest (Shipment { destinationPostalCode: PostalCode postalCode, weight: Weight weight }) =
  { postalCode
  , weight
  }

toCarrierZRateRequest :: Shipment -> CarrierZRateRequest
toCarrierZRateRequest (Shipment { destinationPostalCode: PostalCode postalCode, weight: Weight weight }) =
  { postalCode
  , weight
  }

carrierXResponseToShippingRate :: CarrierXRateResponse -> ShippingRate
carrierXResponseToShippingRate response = ShippingRate
  { carrier: "CarrierX"
  , amount: response.amount
  }

carrierYResponseToShippingRate :: CarrierYRateResponse -> ShippingRate
carrierYResponseToShippingRate response = ShippingRate
  { carrier: "CarrierY"
  , amount: response.price
  }

carrierZResponseToShippingRate :: CarrierZRateResponse -> ShippingRate
carrierZResponseToShippingRate response = ShippingRate
  { carrier: "CarrierZ"
  , amount: response.amount
  }

runFetchShippingRates
  :: Dependencies
  -> Shipment
  -> Aff (Either FetchShippingRatesError ShippingRates)
runFetchShippingRates dependencies =
  fetchShippingRates
    >>> flip runReaderT dependencies
    >>> runExceptT

createShippingRatePort :: Dependencies -> ShippingRatePort
createShippingRatePort dependencies =
  { fetchShippingRates: runFetchShippingRates dependencies
  }
