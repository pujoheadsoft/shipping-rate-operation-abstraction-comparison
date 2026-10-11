module UseCase.GetShippingRatesSpec (spec) where

import           Data.List.NonEmpty       (NonEmpty (..))
import           Domain.Shipment
import           Domain.ShippingRate
import           Domain.ShippingRates
import           Polysemy
import           Polysemy.Error
import           Test.Hspec
import           Test.MockCat
import           UseCase.GetShippingRates
import           UseCase.ShippingRatePort

spec :: Spec
spec = describe "荷物に対しての送料をすべて取得することができる" do
  it "荷物に対しての送料をすべて取得できる" do
    let shipment = Shipment "111-1111" 10
        rates = ShippingRates (ShippingRate "Carrier X" 100 :| [])
        port = stub (shipment ~> Right rates)
    runUseCase port shipment `shouldBe` Right rates
  it "送料取得エラーが起きた場合はエラーを返す" do
    let shipment = Shipment "111-1111" 10
        port = stub (shipment ~> Left FetchShippingRatesFailed)
    runUseCase port shipment `shouldBe` Left GetShippingRatesFailed

runUseCase
  :: (Shipment -> Either FetchShippingRatesError ShippingRates)
  -> Shipment
  -> Either GetShippingRatesError ShippingRates
runUseCase port =
  run
    . runError @GetShippingRatesError
    . interpret (\case FetchShippingRates shipment -> pure $ port shipment)
    . getShippingRates
