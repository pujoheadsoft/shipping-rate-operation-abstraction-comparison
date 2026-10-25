module UseCase.GetCheapestShippingRate
  ( Dependencies
  , GetCheapestShippingRateError(..)
  , getCheapestShippingRate
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT(..))
import Control.Monad.Reader.Trans (ReaderT(..))
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Domain.PostalCode (PostalCode)
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate)
import Domain.ShippingRates (ShippingRates, findCheapest)
import Domain.UserId (UserId)
import Domain.Weight (Weight)
import Effect.Aff (Aff)
import UseCase.PostalCodePort
  ( FetchPostalCodeError(..)
  , PostalCodePort
  )
import UseCase.ShippingRatePort
  ( FetchShippingRatesError
  , ShippingRatePort
  )

data GetCheapestShippingRateError
  = ShippingDestinationNotFound
  | GetCheapestShippingRateFailed

derive instance Eq GetCheapestShippingRateError

instance Show GetCheapestShippingRateError where
  show ShippingDestinationNotFound = "ShippingDestinationNotFound"
  show GetCheapestShippingRateFailed = "GetCheapestShippingRateFailed"

type Dependencies =
  { postalCodePort :: PostalCodePort
  , shippingRatePort :: ShippingRatePort
  }

getCheapestShippingRate
  :: UserId
  -> Weight
  -> ReaderT Dependencies
       (ExceptT GetCheapestShippingRateError Aff)
       ShippingRate
getCheapestShippingRate userId weight =
  fetchPostalCode userId
    >>= (toShipment weight >>> fetchShippingRates >>> map findCheapest)
  where
  fetchPostalCode
    :: UserId
    -> ReaderT Dependencies
         (ExceptT GetCheapestShippingRateError Aff)
         PostalCode
  fetchPostalCode requestedUserId = ReaderT $
    _.postalCodePort
      >>> _.fetchPostalCodeByUserId
      >>> (_ $ requestedUserId)
      >>> liftPostalCodeResult

  liftPostalCodeResult
    :: Aff (Either FetchPostalCodeError PostalCode)
    -> ExceptT GetCheapestShippingRateError Aff PostalCode
  liftPostalCodeResult action =
    ExceptT $ lmap toUseCasePostalCodeError <$> action

  toUseCasePostalCodeError :: FetchPostalCodeError -> GetCheapestShippingRateError
  toUseCasePostalCodeError PostalCodeNotFound = ShippingDestinationNotFound
  toUseCasePostalCodeError FetchPostalCodeFailed = GetCheapestShippingRateFailed

  toShipment :: Weight -> PostalCode -> Shipment
  toShipment shipmentWeight destinationPostalCode =
    Shipment { destinationPostalCode, weight: shipmentWeight }

  fetchShippingRates
    :: Shipment
    -> ReaderT Dependencies
         (ExceptT GetCheapestShippingRateError Aff)
         ShippingRates
  fetchShippingRates shipment = ReaderT $
    _.shippingRatePort
      >>> _.fetchShippingRates
      >>> (_ $ shipment)
      >>> liftShippingRatesResult

  liftShippingRatesResult
    :: Aff (Either FetchShippingRatesError ShippingRates)
    -> ExceptT GetCheapestShippingRateError Aff ShippingRates
  liftShippingRatesResult action =
    ExceptT $ lmap (const GetCheapestShippingRateFailed) <$> action
