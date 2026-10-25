module Gateway.ShippingRatesGatewaySpec (spec) where

import           Data.List.NonEmpty        (NonEmpty (..))
import           Domain.PostalCode
import           Domain.Shipment
import           Domain.ShippingRate
import           Domain.ShippingRates
import           Domain.Weight
import qualified Gateway.CarrierXApiClient as X
import qualified Gateway.CarrierYApiClient as Y
import qualified Gateway.CarrierZApiClient as Z
import           Test.Hspec
import           Test.MockCat
import           TestSupport               (runGateway)
import           UseCase.ShippingRatePort

spec :: Spec
spec = describe "送料を取得する" do
  it "3社へリクエストを送り、すべての送料を取得できる" do
    let x = stub $ X.CarrierXRateRequest "111-1111" 1000 ~>
          Right (X.CarrierXRateResponse 1000 "EXPRESS")

        y = stub $ Y.CarrierYRateRequest "111-1111" 1000 ~>
          Right (Y.CarrierYRateResponse 2000 "Standard Delivery")

        z = stub $ Z.CarrierZRateRequest "111-1111" 1000 ~>
          Right (Z.CarrierZRateResponse 3000 "ECONOMY")

        expected = ShippingRates
          $ ShippingRate "CarrierX" 1000
          :| [ShippingRate "CarrierY" 2000, ShippingRate "CarrierZ" 3000]

    runGateway (pure . x) (pure . y) (pure . z) shipment `shouldReturn` Right expected

  it "Carrier APIでエラーが発生したらFetchShippingRatesFailedを返す" do
    let x = stub $ X.CarrierXRateRequest "111-1111" 1000 ~>
          Right (X.CarrierXRateResponse 1000 "EXPRESS")

        y = stub $ Y.CarrierYRateRequest "111-1111" 1000 ~>
          Left Y.CarrierYApiOperationFailed

        z = stub $ Z.CarrierZRateRequest "111-1111" 1000 ~>
          Right (Z.CarrierZRateResponse 3000 "ECONOMY")

    runGateway (pure . x) (pure . y) (pure . z) shipment `shouldReturn` Left FetchShippingRatesFailed

shipment :: Shipment
shipment = Shipment (PostalCode "111-1111") (Weight 1000)
