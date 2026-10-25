module Test.UseCase.GetCheapestShippingRate (spec) where

import Prelude

import Control.Monad.Except.Trans (runExceptT)
import Control.Monad.Reader.Trans (runReaderT)
import Data.Array.NonEmpty as NonEmptyArray
import Data.Either (Either(..))
import Domain.PostalCode (PostalCode(..))
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Domain.UserId (UserId(..))
import Domain.Weight (Weight(..))
import Effect.Aff (Aff)
import Test.PMock (stub, (:>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import UseCase.GetCheapestShippingRate
  ( Dependencies
  , GetCheapestShippingRateError(..)
  , getCheapestShippingRate
  )
import UseCase.PostalCodePort
  ( FetchPostalCodeError(..)
  )
import UseCase.ShippingRatePort
  ( FetchShippingRatesError(..)
  )

spec :: Spec Unit
spec = describe "ユーザーの配送先に対する最安送料を取得する" do
  it "一番安い送料を取得できる" do
    let
      userId = UserId "userId"
      weight = Weight 500
      postalCode = PostalCode "111-1111"
      shipment = Shipment { destinationPostalCode: postalCode, weight }
      rates = ShippingRates $ NonEmptyArray.cons'
        (ShippingRate { carrier: "配送業者X", amount: 200 })
        [ ShippingRate { carrier: "配送業者Y", amount: 100 }
        , ShippingRate { carrier: "配送業者Z", amount: 300 }
        ]
      dependencies =
        { postalCodePort:
            { fetchPostalCodeByUserId: stub $ userId :>
                (pure (Right postalCode) :: Aff (Either FetchPostalCodeError PostalCode))
            }
        , shippingRatePort:
            { fetchShippingRates: stub $ shipment :>
                (pure (Right rates) :: Aff (Either FetchShippingRatesError ShippingRates))
            }
        } :: Dependencies

    actual <- runExceptT $ runReaderT
      (getCheapestShippingRate userId weight)
      dependencies

    actual `shouldEqual`
      Right (ShippingRate { carrier: "配送業者Y", amount: 100 })

  it "郵便番号の取得に失敗したらユースケースのエラーを返す" do
    let
      userId = UserId "userId"
      weight = Weight 500
      dependencies =
        { postalCodePort:
            { fetchPostalCodeByUserId: stub $ userId :>
                (pure (Left FetchPostalCodeFailed) :: Aff (Either FetchPostalCodeError PostalCode))
            }
        , shippingRatePort:
            { fetchShippingRates: \_ ->
                pure (Left FetchShippingRatesFailed)
            }
        } :: Dependencies

    actual <- runExceptT $ runReaderT
      (getCheapestShippingRate userId weight)
      dependencies

    actual `shouldEqual` Left GetCheapestShippingRateFailed

  it "郵便番号が存在しなければ配送先未登録エラーを返す" do
    let
      userId = UserId "unknown"
      weight = Weight 500
      dependencies =
        { postalCodePort:
            { fetchPostalCodeByUserId: stub $ userId :>
                (pure (Left PostalCodeNotFound) :: Aff (Either FetchPostalCodeError PostalCode))
            }
        , shippingRatePort:
            { fetchShippingRates: \_ ->
                pure (Left FetchShippingRatesFailed)
            }
        } :: Dependencies

    actual <- runExceptT $ runReaderT
      (getCheapestShippingRate userId weight)
      dependencies

    actual `shouldEqual` Left ShippingDestinationNotFound

  it "送料の取得に失敗したらユースケースのエラーを返す" do
    let
      userId = UserId "userId"
      weight = Weight 500
      postalCode = PostalCode "111-1111"
      shipment = Shipment { destinationPostalCode: postalCode, weight }
      dependencies =
        { postalCodePort:
            { fetchPostalCodeByUserId: stub $ userId :>
                (pure (Right postalCode) :: Aff (Either FetchPostalCodeError PostalCode))
            }
        , shippingRatePort:
            { fetchShippingRates: stub $ shipment :>
                (pure (Left FetchShippingRatesFailed) :: Aff (Either FetchShippingRatesError ShippingRates))
            }
        } :: Dependencies

    actual <- runExceptT $ runReaderT
      (getCheapestShippingRate userId weight)
      dependencies

    actual `shouldEqual` Left GetCheapestShippingRateFailed
