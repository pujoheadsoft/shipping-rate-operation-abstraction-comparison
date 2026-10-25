module UseCase.GetCheapestShippingRate where

import Domain.Shipment (Shipment (..))
import Domain.ShippingRate (ShippingRate)
import Domain.ShippingRates (findCheapest)
import Domain.UserId (UserId)
import Domain.Weight (Weight)
import Effectful (Eff, (:>))
import Effectful.Error.Static (Error, throwError)
import UseCase.PostalCodePort
import UseCase.ShippingRatePort

data GetCheapestShippingRateError
  = ShippingDestinationNotFound
  | GetCheapestShippingRateFailed
  deriving (Eq, Show)

getCheapestShippingRate
  :: ( PostalCodePort :> es
     , ShippingRatePort :> es
     , Error GetCheapestShippingRateError :> es
     )
  => UserId
  -> Weight
  -> Eff es ShippingRate
getCheapestShippingRate userId weight = do
  postalCode <- fetchPostalCodeByUserId userId
    >>= either (throwError . toUseCasePostalCodeError) pure
  rates <- fetchShippingRates (Shipment postalCode weight)
    >>= either (const $ throwError GetCheapestShippingRateFailed) pure
  pure $ findCheapest rates
  where
    toUseCasePostalCodeError PostalCodeNotFound = ShippingDestinationNotFound
    toUseCasePostalCodeError FetchPostalCodeFailed = GetCheapestShippingRateFailed
