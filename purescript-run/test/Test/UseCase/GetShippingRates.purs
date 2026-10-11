module Test.UseCase.GetShippingRates (spec) where

import Prelude
import Data.Either (Either(..))
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Run as Run
import Test.PMock (stub, (:>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import UseCase.GetShippingRates (GetShippingRatesError(..), getShippingRates)
import UseCase.ShippingRatePort (FetchShippingRatesError(..), ShippingRatePortF(..))

spec :: Spec Unit
spec = describe "荷物に対しての送料をすべて取得することができる" do
  it "荷物に対しての送料をすべて取得できる" do
    let
      shipment = Shipment { destinationPostalCode: "111-1111", weight: 10 }
      rates = ShippingRates { head: ShippingRate { carrier: "Carrier X", amount: 100 }, tail: [] }
      response = stub $ shipment :> Right rates
      actual = Run.extract
        $ ( Run.run $ Run.match
              { shippingRatePort: case _ of
                  FetchShippingRates value next -> next <$> pure (response value)
              }
          )
        $ getShippingRates shipment
    actual `shouldEqual` Right rates

  it "送料取得エラーが起きた場合はエラーを返す" do
    let
      shipment = Shipment { destinationPostalCode: "111-1111", weight: 10 }
      response = stub $ shipment :> Left FetchShippingRatesFailed
      actual = Run.extract
        $ ( Run.run $ Run.match
              { shippingRatePort: case _ of
                  FetchShippingRates value next -> next <$> pure (response value)
              }
          )
        $ getShippingRates shipment
    actual `shouldEqual` Left GetShippingRatesFailed
