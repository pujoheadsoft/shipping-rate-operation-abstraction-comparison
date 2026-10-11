module Gateway.ShippingRatesGatewayConcurrencySpec (spec) where

import qualified Control.Concurrent.Async     as IO
import           Control.Concurrent.STM
import           Control.Exception            (finally)
import           Data.List.NonEmpty           (NonEmpty (..))
import           Domain.Shipment
import           Domain.ShippingRate
import           Domain.ShippingRates
import qualified Gateway.CarrierXApiClient    as X
import qualified Gateway.CarrierYApiClient    as Y
import qualified Gateway.CarrierZApiClient    as Z
import qualified Gateway.ShippingRatesGateway as Gateway
import           Polysemy
import           Polysemy.Async
import           Polysemy.Error
import           Polysemy.Resource            (resourceToIOFinal)
import           System.Timeout               (timeout)
import           Test.Hspec
import           UseCase.ShippingRatePort

spec :: Spec
spec = describe "送料取得の並行実行" do
  it "未解釈Carrier effectの3つのbranchが重なる" do
    started <- newTVarIO (0 :: Int)
    release <- newEmptyTMVarIO
    let gate :: response -> request -> IO (Either error response)
        gate value _ = do
          atomically $ modifyTVar' started (+1)
          atomically $ readTVar started >>= check . (== 3)
          atomically $ readTMVar release
          pure $ Right value
        expected = ShippingRates
          ( ShippingRate "CarrierX" 1
          :| [ShippingRate "CarrierY" 2, ShippingRate "CarrierZ" 3]
          )
    IO.withAsync
      (runGateway
        (gate $ X.CarrierXRateResponse 1 "EXPRESS")
        (gate $ Y.CarrierYRateResponse 2 "Standard Delivery")
        (gate $ Z.CarrierZRateResponse 3 "ECONOMY")
        (Shipment "111-1111" 1000))
      $ \worker -> do
          timeout 2000000 (atomically $ readTVar started >>= check . (== 3))
            `shouldReturn` Just ()
          atomically $ putTMVar release ()
          timeout 2000000 (IO.wait worker)
            `shouldReturn` Just (Right expected)

  it "親計算をcancelすると待機中の3つのbranchも終了する" do
    started <- newTVarIO (0 :: Int)
    stopped <- newTVarIO (0 :: Int)
    let waitForever :: request -> IO (Either error response)
        waitForever _ =
          (atomically (modifyTVar' started (+1)) >> atomically retry)
            `finally` atomically (modifyTVar' stopped (+1))
    IO.withAsync
      (runGateway waitForever waitForever waitForever (Shipment "111-1111" 1000))
      $ \worker -> do
          timeout 2000000 (atomically $ readTVar started >>= check . (== 3))
            `shouldReturn` Just ()
          IO.cancel worker
          timeout 2000000 (atomically $ readTVar stopped >>= check . (== 3))
            `shouldReturn` Just ()

runGateway
  :: (X.CarrierXRateRequest -> IO (Either X.CarrierXApiError X.CarrierXRateResponse))
  -> (Y.CarrierYRateRequest -> IO (Either Y.CarrierYApiError Y.CarrierYRateResponse))
  -> (Z.CarrierZRateRequest -> IO (Either Z.CarrierZApiError Z.CarrierZRateResponse))
  -> Shipment
  -> IO (Either FetchShippingRatesError ShippingRates)
runGateway x y z =
  runFinal
    . embedToFinal @IO
    . resourceToIOFinal
    . asyncToIOFinal
    . runError @FetchShippingRatesError
    . interpret (\case Z.FetchRateZ request -> embed $ z request)
    . interpret (\case Y.FetchRateY request -> embed $ y request)
    . interpret (\case X.FetchRateX request -> embed $ x request)
    . Gateway.fetchShippingRates
