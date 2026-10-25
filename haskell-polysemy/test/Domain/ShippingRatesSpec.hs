module Domain.ShippingRatesSpec (spec) where

import Data.List.NonEmpty (NonEmpty (..))
import Domain.ShippingRate
import Domain.ShippingRates
import Test.Hspec

spec :: Spec
spec = describe "一番安い送料を探す" do
  it "一番安い送料を返す" do
    let rates = ShippingRates
          ( ShippingRate "配送業者X" 200
          :| [ShippingRate "配送業者Y" 100, ShippingRate "配送業者Z" 300]
          )
    findCheapest rates `shouldBe` ShippingRate "配送業者Y" 100

  it "最安が複数あるなら最初に見つかったものを返す" do
    let rates = ShippingRates
          ( ShippingRate "配送業者X" 200
          :| [ShippingRate "配送業者Y" 100, ShippingRate "配送業者Z" 100]
          )
    findCheapest rates `shouldBe` ShippingRate "配送業者Y" 100
