module UseCase.GetCheapestShippingRate where

import Control.Monad ((>=>))
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
getCheapestShippingRate userId weight =
  fetchPostalCode
    >=> fetchShippingRatesFor weight
    >=> pure . findCheapest
    $ userId
  where
    fetchPostalCode requestedUserId =
      fetchPostalCodeByUserId requestedUserId
        >>= rethrowWith toUseCasePostalCodeError

    fetchRates shipment =
      fetchShippingRates shipment
        >>= rethrowWith (const GetCheapestShippingRateFailed)

    fetchShippingRatesFor shipmentWeight =
      fetchRates . (`Shipment` shipmentWeight)

    rethrowWith mapError = either (throwError . mapError) pure

    toUseCasePostalCodeError PostalCodeNotFound = ShippingDestinationNotFound
    toUseCasePostalCodeError FetchPostalCodeFailed = GetCheapestShippingRateFailed
