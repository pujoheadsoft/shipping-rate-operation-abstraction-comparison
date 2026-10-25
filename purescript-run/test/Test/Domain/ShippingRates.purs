module Test.Domain.ShippingRates (spec) where

import Prelude
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..), findCheapest)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "一番安い送料を探す" do
  it "一番安い送料を返す" do
    let rates = ShippingRates
          { head: ShippingRate { carrier: "配送業者X", amount: 200 }
          , tail:
              [ ShippingRate { carrier: "配送業者Y", amount: 100 }
              , ShippingRate { carrier: "配送業者Z", amount: 300 }
              ]
          }
    findCheapest rates `shouldEqual`
      ShippingRate { carrier: "配送業者Y", amount: 100 }

  it "最安が複数あるなら最初に見つかったものを返す" do
    let rates = ShippingRates
          { head: ShippingRate { carrier: "配送業者X", amount: 200 }
          , tail:
              [ ShippingRate { carrier: "配送業者Y", amount: 100 }
              , ShippingRate { carrier: "配送業者Z", amount: 100 }
              ]
          }
    findCheapest rates `shouldEqual`
      ShippingRate { carrier: "配送業者Y", amount: 100 }
