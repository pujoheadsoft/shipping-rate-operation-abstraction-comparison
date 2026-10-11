module Test.Gateway.ShippingRatesGateway (spec) where

import Prelude

import Control.Monad.Except.Trans (runExceptT)
import Control.Monad.Reader.Trans (runReaderT)
import Data.Array.NonEmpty as NonEmptyArray
import Data.Either (Either(..))
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Effect.Aff (Aff)
import Gateway.CarrierXApiClient
  ( CarrierXApiError
  , CarrierXRateRequest
  , CarrierXRateResponse
  )
import Gateway.CarrierYApiClient
  ( CarrierYApiError(..)
  , CarrierYRateRequest
  , CarrierYRateResponse
  )
import Gateway.CarrierZApiClient
  ( CarrierZApiError
  , CarrierZRateRequest
  , CarrierZRateResponse
  )
import Gateway.ShippingRatesGateway
  ( Dependencies
  , fetchShippingRates
  )
import Test.PMock (stub, (:>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import UseCase.ShippingRatePort (FetchShippingRatesError(..))

spec :: Spec Unit
spec = describe "送料を取得する" do
  it "3社へリクエストを送り、すべての送料を取得できる" do
    let
      shipment = Shipment { destinationPostalCode: "111-1111", weight: 1000 }

      requestX = { destination: "111-1111", weightGrams: 1000 } :: CarrierXRateRequest
      requestY = { postalCode: "111-1111", weight: 1000 } :: CarrierYRateRequest
      requestZ = { postalCode: "111-1111", weight: 1000 } :: CarrierZRateRequest
      responseX = { amount: 1000, serviceCode: "EXPRESS" } :: CarrierXRateResponse
      responseY = { price: 2000, serviceName: "Standard Delivery" } :: CarrierYRateResponse
      responseZ = { amount: 3000, serviceCode: "ECONOMY" } :: CarrierZRateResponse

      dependencies =
        { carrierXApiClient: { fetchRate: stub $ requestX :> (pure (Right responseX) :: Aff (Either CarrierXApiError CarrierXRateResponse)) }
        , carrierYApiClient: { fetchRate: stub $ requestY :> (pure (Right responseY) :: Aff (Either CarrierYApiError CarrierYRateResponse)) }
        , carrierZApiClient: { fetchRate: stub $ requestZ :> (pure (Right responseZ) :: Aff (Either CarrierZApiError CarrierZRateResponse)) }
        } :: Dependencies
      
      rateX = ShippingRate { carrier: "CarrierX", amount: 1000 }
      rateY = ShippingRate { carrier: "CarrierY", amount: 2000 }
      rateZ = ShippingRate { carrier: "CarrierZ", amount: 3000 }
      expectedRates = ShippingRates $ NonEmptyArray.cons' rateX [ rateY, rateZ ]

    actual <- runExceptT $ runReaderT (fetchShippingRates shipment) dependencies

    actual `shouldEqual` Right expectedRates

  it "エラーが発生した場合は送料取得エラーを返す" do
    let
      shipment = Shipment { destinationPostalCode: "111-1111", weight: 1000 }
      requestX = { destination: "111-1111", weightGrams: 1000 } :: CarrierXRateRequest
      requestY = { postalCode: "111-1111", weight: 1000 } :: CarrierYRateRequest
      requestZ = { postalCode: "111-1111", weight: 1000 } :: CarrierZRateRequest
      responseX = { amount: 1000, serviceCode: "EXPRESS" } :: CarrierXRateResponse
      responseZ = { amount: 3000, serviceCode: "ECONOMY" } :: CarrierZRateResponse
      dependencies =
        { carrierXApiClient: { fetchRate: stub $ requestX :> (pure (Right responseX) :: Aff (Either CarrierXApiError CarrierXRateResponse)) }
        , carrierYApiClient: { fetchRate: stub $ requestY :> (pure (Left CarrierYApiOperationFailed) :: Aff (Either CarrierYApiError CarrierYRateResponse)) }
        , carrierZApiClient: { fetchRate: stub $ requestZ :> (pure (Right responseZ) :: Aff (Either CarrierZApiError CarrierZRateResponse)) }
        } :: Dependencies

    actual <- runExceptT $ runReaderT (fetchShippingRates shipment) dependencies

    actual `shouldEqual` Left FetchShippingRatesFailed
