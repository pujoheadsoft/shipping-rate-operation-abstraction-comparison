module UseCase.GetCheapestShippingRate where

import Domain.Shipment (Shipment (..))
import Domain.ShippingRate (ShippingRate)
import Domain.ShippingRates (findCheapest)
import Domain.UserId (UserId)
import Domain.Weight (Weight)
import Polysemy (Members, Sem)
import Polysemy.Error (Error, throw)
import UseCase.PostalCodePort
import UseCase.ShippingRatePort

data GetCheapestShippingRateError
  = ShippingDestinationNotFound
  | GetCheapestShippingRateFailed
  deriving (Eq, Show)

getCheapestShippingRate
  :: Members
       '[ PostalCodePort
        , ShippingRatePort
        , Error GetCheapestShippingRateError
        ] r
  => UserId
  -> Weight
  -> Sem r ShippingRate
getCheapestShippingRate userId weight = do
  postalCode <- fetchPostalCodeByUserId userId
    >>= either (throw . toUseCasePostalCodeError) pure
  rates <- fetchShippingRates (Shipment postalCode weight)
    >>= either (const $ throw GetCheapestShippingRateFailed) pure
  pure $ findCheapest rates
  where
    toUseCasePostalCodeError PostalCodeNotFound = ShippingDestinationNotFound
    toUseCasePostalCodeError FetchPostalCodeFailed = GetCheapestShippingRateFailed
