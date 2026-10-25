module Gateway.ShippingRatesGatewaySpec (spec) where

import           Data.List.NonEmpty           (NonEmpty (..))
import           Domain.PostalCode
import           Domain.Shipment
import           Domain.ShippingRate
import           Domain.ShippingRates
import           Domain.Weight
import qualified Gateway.CarrierXApiClient    as X
import qualified Gateway.CarrierYApiClient    as Y
import qualified Gateway.CarrierZApiClient    as Z
import qualified Gateway.ShippingRatesGateway as Gateway
import           Polysemy
import           Polysemy.Async
import           Polysemy.Error
import           Polysemy.Resource            (resourceToIOFinal)
import           Test.Hspec
import           Test.MockCat
import           UseCase.ShippingRatePort

spec :: Spec
spec = describe "送料を取得する" do
  it "3社へリクエストを送り、すべての送料を取得できる" do
    let x = stub
          (X.CarrierXRateRequest "111-1111" 1000 ~>
            Right (X.CarrierXRateResponse 1000 "EXPRESS"))

        y = stub
          (Y.CarrierYRateRequest "111-1111" 1000 ~>
            Right (Y.CarrierYRateResponse 2000 "Standard Delivery"))

        z = stub
          (Z.CarrierZRateRequest "111-1111" 1000 ~>
            Right (Z.CarrierZRateResponse 3000 "ECONOMY"))

        expected = ShippingRates
          ( ShippingRate "CarrierX" 1000
          :| [ShippingRate "CarrierY" 2000, ShippingRate "CarrierZ" 3000]
          )

    runGateway x y z shipment `shouldReturn` Right expected

  it "Carrier APIでエラーが発生したらFetchShippingRatesFailedを返す" do
    let x = stub
          (X.CarrierXRateRequest "111-1111" 1000 ~>
            Right (X.CarrierXRateResponse 1000 "EXPRESS"))

        y = stub
          (Y.CarrierYRateRequest "111-1111" 1000 ~>
            Left Y.CarrierYApiOperationFailed)

        z = stub
          (Z.CarrierZRateRequest "111-1111" 1000 ~>
            Right (Z.CarrierZRateResponse 3000 "ECONOMY"))

    runGateway x y z shipment `shouldReturn` Left FetchShippingRatesFailed

shipment :: Shipment
shipment = Shipment (PostalCode "111-1111") (Weight 1000)

runGateway
  :: (X.CarrierXRateRequest -> Either X.CarrierXApiError X.CarrierXRateResponse)
  -> (Y.CarrierYRateRequest -> Either Y.CarrierYApiError Y.CarrierYRateResponse)
  -> (Z.CarrierZRateRequest -> Either Z.CarrierZApiError Z.CarrierZRateResponse)
  -> Shipment
  -> IO (Either FetchShippingRatesError ShippingRates)
runGateway x y z =
  runFinal
    . resourceToIOFinal
    . asyncToIOFinal
    . runError @FetchShippingRatesError
    . interpret (\case Z.FetchRateZ request -> pure $ z request)
    . interpret (\case Y.FetchRateY request -> pure $ y request)
    . interpret (\case X.FetchRateX request -> pure $ x request)
    . Gateway.fetchShippingRates
