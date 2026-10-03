module Test.UseCase.GetShippingRates (spec) where

import Prelude

import Control.Monad.Reader.Trans (runReaderT)
import Data.Array.NonEmpty as NonEmptyArray
import Data.Either (Either(..))
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Effect.Aff (Aff)
import Port.ShippingRateError (FetchShippingRatesError(..))
import Port.ShippingRatePort (ShippingRatePort)
import Test.PMock (stub, (:>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import UseCase.GetShippingRates (getShippingRates)
import UseCase.GetShippingRatesError (GetShippingRatesError(..))

spec :: Spec Unit
spec = describe "荷物に対しての送料をすべて取得することができる" do
  it "荷物に対しての送料をすべて取得できる" do
    let
      shipment = Shipment
        { destinationPostalCode: "111-1111"
        , weight: 10
        }
      expectedRates = ShippingRates $ NonEmptyArray.singleton $ ShippingRate
        { carrier: "Carrier X"
        , amount: 100
        }

    let
      fetchShippingRates = stub $
        shipment :> (pure (Right expectedRates) :: Aff (Either FetchShippingRatesError ShippingRates))
      port = { fetchShippingRates } :: ShippingRatePort

    actual <- runReaderT (getShippingRates shipment) port

    actual `shouldEqual` Right expectedRates

  it "送料の取得でエラーが起きた場合エラーが返される" do
    let
      shipment = Shipment
        { destinationPostalCode: "111-1111"
        , weight: 10
        }

    let
      fetchShippingRates = stub $
        shipment :> (pure (Left FetchShippingRatesFailed) :: Aff (Either FetchShippingRatesError ShippingRates))
      port = { fetchShippingRates } :: ShippingRatePort

    actual <- runReaderT (getShippingRates shipment) port

    actual `shouldEqual` Left GetShippingRatesFailed
