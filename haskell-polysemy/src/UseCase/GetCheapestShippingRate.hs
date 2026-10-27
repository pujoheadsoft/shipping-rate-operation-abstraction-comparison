module UseCase.GetCheapestShippingRate where

import Control.Monad ((>=>))
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

    rethrowWith mapError = either (throw . mapError) pure

    toUseCasePostalCodeError PostalCodeNotFound = ShippingDestinationNotFound
    toUseCasePostalCodeError FetchPostalCodeFailed = GetCheapestShippingRateFailed
