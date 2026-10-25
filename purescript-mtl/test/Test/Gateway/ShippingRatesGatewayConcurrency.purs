module Test.Gateway.ShippingRatesGatewayConcurrency (spec) where

import Prelude

import Control.Monad.Except.Trans (runExceptT)
import Control.Monad.Reader.Trans (runReaderT)
import Data.Either (Either(..))
import Data.Array.NonEmpty as NonEmptyArray
import Domain.PostalCode (PostalCode(..))
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Domain.Weight (Weight(..))
import Effect.Aff (bracket, forkAff, joinFiber, killFiber)
import Effect.Aff.AVar as AVar
import Effect.Exception (error)
import Gateway.ShippingRatesGateway (fetchShippingRates)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "送料取得の並行実行" do
  it "ReaderT / ExceptT上の3つのAff branchが重なる" do
    sx <- AVar.empty
    sy <- AVar.empty
    sz <- AVar.empty
    rx <- AVar.empty
    ry <- AVar.empty
    rz <- AVar.empty
    let
      clientX _ = AVar.put unit sx *> AVar.take rx
        $> Right { amount: 1, serviceCode: "EXPRESS" }
      clientY _ = AVar.put unit sy *> AVar.take ry
        $> Right { price: 2, serviceName: "Standard Delivery" }
      clientZ _ = AVar.put unit sz *> AVar.take rz
        $> Right { amount: 3, serviceCode: "ECONOMY" }
      dependencies =
        { carrierXApiClient: { fetchRate: clientX }
        , carrierYApiClient: { fetchRate: clientY }
        , carrierZApiClient: { fetchRate: clientZ }
        }
      expected = ShippingRates $ NonEmptyArray.cons'
        (ShippingRate { carrier: "CarrierX", amount: 1 })
        [ ShippingRate { carrier: "CarrierY", amount: 2 }
        , ShippingRate { carrier: "CarrierZ", amount: 3 }
        ]
      action = runExceptT $ runReaderT
        (fetchShippingRates $ Shipment
          { destinationPostalCode: PostalCode "111-1111"
          , weight: Weight 1000
          })
        dependencies
    bracket
      (forkAff action)
      (killFiber $ error "並行性テストを終了")
      \fiber -> do
        _ <- AVar.take sx *> AVar.take sy *> AVar.take sz
        _ <- AVar.put unit rx *> AVar.put unit ry *> AVar.put unit rz
        actual <- joinFiber fiber
        actual `shouldEqual` Right expected
