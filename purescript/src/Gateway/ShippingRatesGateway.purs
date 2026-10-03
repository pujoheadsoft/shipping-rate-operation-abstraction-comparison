module Gateway.ShippingRatesGateway
  ( Dependencies
  , ShippingRateGatewayM
  , createShippingRatePort
  , fetchShippingRates
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT(..), runExceptT)
import Control.Monad.Reader.Trans (ReaderT, asks, lift, runReaderT)
import Control.Parallel (parSequence)
import Data.Array.NonEmpty as NonEmptyArray
import Data.Bifunctor (lmap)
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Effect.Aff (Aff, attempt)
import Gateway.CarrierX
  ( CarrierXRateRequest(..)
  , CarrierXRateResponse(..)
  )
import Gateway.CarrierY
  ( CarrierYRateRequest(..)
  , CarrierYRateResponse(..)
  )
import Gateway.CarrierZ
  ( CarrierZRateRequest(..)
  , CarrierZRateResponse(..)
  )
import Port.ShippingRateError (FetchShippingRatesError(..))
import Port.ShippingRatePort (ShippingRatePort)

type Dependencies =
  { fetchCarrierXRate :: CarrierXRateRequest -> Aff CarrierXRateResponse
  , fetchCarrierYRate :: CarrierYRateRequest -> Aff CarrierYRateResponse
  , fetchCarrierZRate :: CarrierZRateRequest -> Aff CarrierZRateResponse
  }

type ShippingRateGatewayM =
  ReaderT Dependencies (ExceptT FetchShippingRatesError Aff)

fetchShippingRates :: Shipment -> ShippingRateGatewayM ShippingRates
fetchShippingRates shipment =
  ShippingRates <$> parSequence
    (NonEmptyArray.cons'
      (fetchCarrierXRate shipment)
      [ fetchCarrierYRate shipment
      , fetchCarrierZRate shipment 
      ])

fetchCarrierXRate :: Shipment -> ShippingRateGatewayM ShippingRate
fetchCarrierXRate = toCarrierXRateRequest >>> callCarrier _.fetchCarrierXRate >>> map carrierXResponseToShippingRate

fetchCarrierYRate :: Shipment -> ShippingRateGatewayM ShippingRate
fetchCarrierYRate = toCarrierYRateRequest >>> callCarrier _.fetchCarrierYRate >>> map carrierYResponseToShippingRate

fetchCarrierZRate :: Shipment -> ShippingRateGatewayM ShippingRate
fetchCarrierZRate = toCarrierZRateRequest >>> callCarrier _.fetchCarrierZRate >>> map carrierZResponseToShippingRate

callCarrier
  :: forall request response
   . (Dependencies -> request -> Aff response)
  -> request
  -> ShippingRateGatewayM response
callCarrier selectClient request = do
  fetch <- asks selectClient
  lift $ liftCarrier $ fetch request

liftCarrier :: forall a. Aff a -> ExceptT FetchShippingRatesError Aff a
liftCarrier action =
  ExceptT $ lmap (const FetchShippingRatesFailed) <$> attempt action

toCarrierXRateRequest :: Shipment -> CarrierXRateRequest
toCarrierXRateRequest (Shipment shipment) = CarrierXRateRequest
  { destination: shipment.destinationPostalCode
  , weightGrams: shipment.weight
  }

toCarrierYRateRequest :: Shipment -> CarrierYRateRequest
toCarrierYRateRequest (Shipment shipment) = CarrierYRateRequest
  { postalCode: shipment.destinationPostalCode
  , weight: shipment.weight
  }

toCarrierZRateRequest :: Shipment -> CarrierZRateRequest
toCarrierZRateRequest (Shipment shipment) = CarrierZRateRequest
  { postalCode: shipment.destinationPostalCode
  , weight: shipment.weight
  }

carrierXResponseToShippingRate :: CarrierXRateResponse -> ShippingRate
carrierXResponseToShippingRate (CarrierXRateResponse response) = ShippingRate
  { carrier: response.serviceCode
  , amount: response.amount
  }

carrierYResponseToShippingRate :: CarrierYRateResponse -> ShippingRate
carrierYResponseToShippingRate (CarrierYRateResponse response) = ShippingRate
  { carrier: response.serviceName
  , amount: response.price
  }

carrierZResponseToShippingRate :: CarrierZRateResponse -> ShippingRate
carrierZResponseToShippingRate (CarrierZRateResponse response) = ShippingRate
  { carrier: response.serviceCode
  , amount: response.amount
  }

createShippingRatePort :: Dependencies -> ShippingRatePort
createShippingRatePort dependencies =
  { fetchShippingRates: \shipment ->
      runExceptT $ runReaderT (fetchShippingRates shipment) dependencies
  }
