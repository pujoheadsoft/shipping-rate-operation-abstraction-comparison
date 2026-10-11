module Test.Gateway.ShippingRatesGatewayConcurrency (spec) where

import Prelude

import Control.Monad.Error.Class (throwError)
import Data.Either (Either(..), isLeft)
import Data.Maybe (Maybe(..))
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Effect.Aff (attempt, bracket, finally, forkAff, joinFiber, killFiber)
import Effect.Aff.AVar as AVar
import Effect.Exception (error)
import Gateway.CarrierYApiClient as Y
import Gateway.ShippingRatesGateway (fetchShippingRates)
import Run.Parallel (liftParallel, runParallel)
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Support.RunCarriers (runCarriersWith)
import UseCase.ShippingRatePort (FetchShippingRatesError(..))

shipment :: Shipment
shipment = Shipment { destinationPostalCode: "111-1111", weight: 1000 }

spec :: Spec Unit
spec = describe "送料取得の並行実行" do
  it "未解釈Carrier effectの3つのbranchが重なる" do
    sx <- AVar.empty
    sy <- AVar.empty
    sz <- AVar.empty
    release <- AVar.empty
    let
      clientX _ = AVar.put unit sx *> AVar.read release
        $> Right { amount: 1, serviceCode: "EXPRESS" }
      clientY _ = AVar.put unit sy *> AVar.read release
        $> Right { price: 2, serviceName: "Standard Delivery" }
      clientZ _ = AVar.put unit sz *> AVar.read release
        $> Right { amount: 3, serviceCode: "ECONOMY" }
      expected = ShippingRates
        { head: ShippingRate { carrier: "CarrierX", amount: 1 }
        , tail:
            [ ShippingRate { carrier: "CarrierY", amount: 2 }
            , ShippingRate { carrier: "CarrierZ", amount: 3 }
            ]
        }
      action = runParallel
        (runCarriersWith
          { carrierX: clientX, carrierY: clientY, carrierZ: clientZ })
        (liftParallel $ fetchShippingRates shipment)
    bracket
      (forkAff action)
      (killFiber $ error "並行性テストを終了")
      \fiber -> do
        _ <- AVar.take sx *> AVar.take sy *> AVar.take sz
        _ <- AVar.put unit release
        actual <- joinFiber fiber
        actual `shouldEqual` Right expected

  it "CarrierのLeftは他branchを中断せず、すべての結果を待つ" do
    sx <- AVar.empty
    sz <- AVar.empty
    releaseX <- AVar.empty
    releaseZ <- AVar.empty
    completed <- AVar.empty
    let
      clientX _ = AVar.put unit sx *> AVar.take releaseX
        $> Right { amount: 1, serviceCode: "EXPRESS" }
      clientY _ = pure $ Left Y.CarrierYApiOperationFailed
      clientZ _ = AVar.put unit sz *> AVar.take releaseZ
        $> Right { amount: 3, serviceCode: "ECONOMY" }
      action = runParallel
        (runCarriersWith
          { carrierX: clientX, carrierY: clientY, carrierZ: clientZ })
        (liftParallel $ fetchShippingRates shipment)
    fiber <- forkAff $ action >>= flip AVar.put completed
    _ <- AVar.take sx *> AVar.take sz
    beforeRelease <- AVar.tryRead completed
    beforeRelease `shouldEqual` Nothing
    _ <- AVar.put unit releaseX *> AVar.put unit releaseZ
    actual <- AVar.take completed
    actual `shouldEqual` Left FetchShippingRatesFailed
    _ <- joinFiber fiber
    pure unit

  it "親計算をcancelすると待機中の3つのbranchも終了する" do
    sx <- AVar.empty
    sy <- AVar.empty
    sz <- AVar.empty
    tx <- AVar.empty
    ty <- AVar.empty
    tz <- AVar.empty
    neverX <- AVar.empty
    neverY <- AVar.empty
    neverZ <- AVar.empty
    let
      clientX _ = finally (AVar.put unit tx) $ AVar.put unit sx *> AVar.take neverX
      clientY _ = finally (AVar.put unit ty) $ AVar.put unit sy *> AVar.take neverY
      clientZ _ = finally (AVar.put unit tz) $ AVar.put unit sz *> AVar.take neverZ
      action = runParallel
        (runCarriersWith
          { carrierX: clientX, carrierY: clientY, carrierZ: clientZ })
        (liftParallel $ fetchShippingRates shipment)
    fiber <- forkAff action
    _ <- AVar.take sx *> AVar.take sy *> AVar.take sz
    _ <- killFiber (error "親計算をcancel") fiber
    _ <- AVar.take tx *> AVar.take ty *> AVar.take tz
    pure unit

  it "Affの失敗は待機中の兄弟branchを中断する" do
    sx <- AVar.empty
    sz <- AVar.empty
    tx <- AVar.empty
    tz <- AVar.empty
    neverX <- AVar.empty
    neverZ <- AVar.empty
    let
      clientX _ = finally (AVar.put unit tx) $ AVar.put unit sx *> AVar.take neverX
      clientY _ = AVar.take sx *> AVar.take sz *> throwError (error "Aff failure")
      clientZ _ = finally (AVar.put unit tz) $ AVar.put unit sz *> AVar.take neverZ
      action = runParallel
        (runCarriersWith
          { carrierX: clientX, carrierY: clientY, carrierZ: clientZ })
        (liftParallel $ fetchShippingRates shipment)
    result <- attempt action
    isLeft result `shouldEqual` true
    _ <- AVar.take tx *> AVar.take tz
    pure unit
