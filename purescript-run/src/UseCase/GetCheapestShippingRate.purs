module UseCase.GetCheapestShippingRate
  ( GetCheapestShippingRateError(..)
  , getCheapestShippingRate
  ) where

import Prelude
import Data.Bifunctor (lmap)
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
getCheapestShippingRate userId weight = do
  postalCode <- PostalCodePort.fetchPostalCodeByUserId userId
    >>= RunExcept.rethrow <<< lmap toUseCasePostalCodeError
  rates <- ShippingRatePort.fetchShippingRates
      (Shipment { destinationPostalCode: postalCode, weight })
    >>= RunExcept.rethrow <<< lmap (const GetCheapestShippingRateFailed)
  pure $ findCheapest rates
  where
  toUseCasePostalCodeError PostalCodePort.PostalCodeNotFound =
    ShippingDestinationNotFound
  toUseCasePostalCodeError PostalCodePort.FetchPostalCodeFailed =
    GetCheapestShippingRateFailed
