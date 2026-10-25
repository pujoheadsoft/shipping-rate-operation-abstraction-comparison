module Test.Gateway.ShippingRatesGateway (spec) where

import Prelude

import Data.Either (Either(..))
import Domain.PostalCode (PostalCode(..))
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Domain.Weight (Weight(..))
import Effect.Aff (Aff)
import Gateway.CarrierXApiClient as X
import Gateway.CarrierYApiClient as Y
import Gateway.CarrierZApiClient as Z
import Gateway.ShippingRatesGateway (fetchShippingRates)
import Run.Parallel (liftParallel, runParallel)
import Test.PMock (stub, (:>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import Test.Support.RunCarriers (runCarriersWith)
import UseCase.ShippingRatePort (FetchShippingRatesError(..))

spec :: Spec Unit
spec = describe "送料を取得する" do
  it "3社へリクエストを送り、すべての送料を取得できる" do
    let
      requestX = { destination: "111-1111", weightGrams: 1000 }
      requestY = { postalCode: "111-1111", weight: 1000 }
      requestZ = { postalCode: "111-1111", weight: 1000 }

      responseX =
        Right { amount: 1000, serviceCode: "EXPRESS" }
          :: Either X.CarrierXApiError X.CarrierXRateResponse
      responseY =
        Right { price: 2000, serviceName: "Standard Delivery" }
          :: Either Y.CarrierYApiError Y.CarrierYRateResponse
      responseZ =
        Right { amount: 3000, serviceCode: "ECONOMY" }
          :: Either Z.CarrierZApiError Z.CarrierZRateResponse

      clients =
        { carrierX: stub $ requestX :> (pure responseX :: Aff _)
        , carrierY: stub $ requestY :> (pure responseY :: Aff _)
        , carrierZ: stub $ requestZ :> (pure responseZ :: Aff _)
        }
      expected = ShippingRates
        { head: ShippingRate { carrier: "CarrierX", amount: 1000 }
        , tail:
            [ ShippingRate { carrier: "CarrierY", amount: 2000 }
            , ShippingRate { carrier: "CarrierZ", amount: 3000 }
            ]
        }
      program = liftParallel $ fetchShippingRates $ Shipment
        { destinationPostalCode: PostalCode "111-1111", weight: Weight 1000 }

    actual <- runParallel (runCarriersWith clients) program
    actual `shouldEqual` Right expected

  it "Carrier APIでエラーが発生したらFetchShippingRatesFailedを返す" do
    let
      responseX = Right { amount: 1000, serviceCode: "EXPRESS" }
      responseY = Left Y.CarrierYApiOperationFailed
      responseZ = Right { amount: 3000, serviceCode: "ECONOMY" }
      clients =
        { carrierX: const (pure responseX)
        , carrierY: const (pure responseY)
        , carrierZ: const (pure responseZ)
        }
      program = liftParallel $ fetchShippingRates $ Shipment
        { destinationPostalCode: PostalCode "111-1111", weight: Weight 1000 }

    actual <- runParallel (runCarriersWith clients) program
    actual `shouldEqual` Left FetchShippingRatesFailed
