module Test.Gateway.ShippingRatesGateway (spec) where

import Prelude

import Control.Monad.Except.Trans (runExceptT)
import Control.Monad.Reader.Trans (runReaderT)
import Data.Array.NonEmpty as NonEmptyArray
import Data.Either (Either(..))
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Effect.Aff (Aff, throwError)
import Effect.Exception (error)
import Gateway.CarrierX
  ( CarrierXRateRequest(..)
  , CarrierXRateResponse(..)
  )
import Gateway.CarrierY
  ( CarrierYRateRequest(..)
  , CarrierYRateResponse(..)
  )
import Gateway.CarrierZ
  ( CarrierZRateRequest(..)
  , CarrierZRateResponse(..)
  )
import Gateway.ShippingRatesGateway
  ( Dependencies
  , fetchShippingRates
  )
import Port.ShippingRateError (FetchShippingRatesError(..))
import Test.PMock (stub, (:>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)

spec :: Spec Unit
spec = describe "送料取得を取得する" do
  it "3社へリクエストを送り、すべての送料を取得できる" do
    let
      shipment = Shipment { destinationPostalCode: "111-1111", weight: 1000 }

      requestX = CarrierXRateRequest { destination: "111-1111", weightGrams: 1000 }
      requestY = CarrierYRateRequest { postalCode: "111-1111", weight: 1000 }
      requestZ = CarrierZRateRequest { postalCode: "111-1111", weight: 1000 }
      responseX = CarrierXRateResponse { amount: 1000, serviceCode: "ServiceCodeX" }
      responseY = CarrierYRateResponse { price: 2000, serviceName: "CarrierY" }
      responseZ = CarrierZRateResponse { amount: 3000, serviceCode: "ServiceCodeZ" }

      dependencies =
        { fetchCarrierXRate: stub $ requestX :> (pure responseX :: Aff CarrierXRateResponse)
        , fetchCarrierYRate: stub $ requestY :> (pure responseY :: Aff CarrierYRateResponse)
        , fetchCarrierZRate: stub $ requestZ :> (pure responseZ :: Aff CarrierZRateResponse)
        } :: Dependencies
      
      rateX = ShippingRate { carrier: "ServiceCodeX", amount: 1000 }
      rateY = ShippingRate { carrier: "CarrierY", amount: 2000 }
      rateZ = ShippingRate { carrier: "ServiceCodeZ", amount: 3000 }
      expectedRates = ShippingRates $ NonEmptyArray.cons' rateX [ rateY, rateZ ]

    actual <- runExceptT $ runReaderT (fetchShippingRates shipment) dependencies

    actual `shouldEqual` Right expectedRates

  it "エラーが発生した場合は送料取得エラーを返す" do
    let
      shipment = Shipment { destinationPostalCode: "111-1111", weight: 1000 }
      requestX = CarrierXRateRequest { destination: "111-1111", weightGrams: 1000 }
      requestY = CarrierYRateRequest { postalCode: "111-1111", weight: 1000 }
      requestZ = CarrierZRateRequest { postalCode: "111-1111", weight: 1000 }
      responseX = CarrierXRateResponse { amount: 1000, serviceCode: "ServiceCodeX" }
      responseZ = CarrierZRateResponse { amount: 3000, serviceCode: "ServiceCodeZ" }
      failureY = throwError (error "Carrier Y failed") :: Aff CarrierYRateResponse
      dependencies =
        { fetchCarrierXRate: stub $ requestX :> (pure responseX :: Aff CarrierXRateResponse)
        , fetchCarrierYRate: stub $ requestY :> failureY
        , fetchCarrierZRate: stub $ requestZ :> (pure responseZ :: Aff CarrierZRateResponse)
        } :: Dependencies

    actual <- runExceptT $ runReaderT (fetchShippingRates shipment) dependencies

    actual `shouldEqual` Left FetchShippingRatesFailed
