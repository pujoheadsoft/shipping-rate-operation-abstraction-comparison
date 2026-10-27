module UseCase.GetCheapestShippingRate
  ( GetCheapestShippingRateError(..)
  , getCheapestShippingRate
  ) where

import Prelude
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate)
import Domain.ShippingRates (findCheapest)
import Domain.UserId (UserId)
import Domain.Weight (Weight)
import Run (Run)
import Run.Except as RunExcept
import Type.Row (type (+))
import UseCase.PostalCodePort as PostalCodePort
import UseCase.ShippingRatePort as ShippingRatePort

data GetCheapestShippingRateError
  = ShippingDestinationNotFound
  | GetCheapestShippingRateFailed

derive instance Eq GetCheapestShippingRateError
instance Show GetCheapestShippingRateError where
  show ShippingDestinationNotFound = "ShippingDestinationNotFound"
  show GetCheapestShippingRateFailed = "GetCheapestShippingRateFailed"

getCheapestShippingRate
  :: forall r
   . UserId
  -> Weight
  -> Run
       ( RunExcept.EXCEPT GetCheapestShippingRateError
       + ( postalCodePort :: PostalCodePort.POSTAL_CODE_PORT
         , shippingRatePort :: ShippingRatePort.SHIPPING_RATE_PORT
         | r
         )
       )
       ShippingRate
getCheapestShippingRate userId weight =
  fetchPostalCode
    >=> fetchShippingRatesFor weight
    >=> pure <<< findCheapest
    $ userId
  where
  fetchPostalCode =
    PostalCodePort.fetchPostalCodeByUserId
      >=> rethrowWith toUseCasePostalCodeError

  fetchShippingRates =
    ShippingRatePort.fetchShippingRates
      >=> rethrowWith (const GetCheapestShippingRateFailed)

  fetchShippingRatesFor shipmentWeight =
    toShipment shipmentWeight
      >>> fetchShippingRates

  toShipment shipmentWeight destinationPostalCode =
    Shipment { destinationPostalCode, weight: shipmentWeight }

  toUseCasePostalCodeError PostalCodePort.PostalCodeNotFound =
    ShippingDestinationNotFound
  toUseCasePostalCodeError PostalCodePort.FetchPostalCodeFailed =
    GetCheapestShippingRateFailed

rethrowWith
  :: forall e a r
   . (e -> GetCheapestShippingRateError)
  -> Either e a
  -> Run (RunExcept.EXCEPT GetCheapestShippingRateError + r) a
rethrowWith mapError = RunExcept.rethrow <<< lmap mapError
