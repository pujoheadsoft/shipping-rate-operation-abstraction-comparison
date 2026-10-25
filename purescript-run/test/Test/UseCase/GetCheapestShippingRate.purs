module Test.UseCase.GetCheapestShippingRate (spec) where

import Prelude
import Data.Either (Either(..))
import Domain.PostalCode (PostalCode(..))
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Domain.UserId (UserId(..))
import Domain.Weight (Weight(..))
import Run as Run
import Run.Except as RunExcept
import Test.PMock (stub, (:>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import UseCase.GetCheapestShippingRate
  ( GetCheapestShippingRateError(..)
  , getCheapestShippingRate
  )
import UseCase.PostalCodePort
  ( FetchPostalCodeError(..)
  , PostalCodePortF(..)
  )
import UseCase.ShippingRatePort
  ( FetchShippingRatesError(..)
  , ShippingRatePortF(..)
  )

spec :: Spec Unit
spec = describe "ユーザーの配送先に対する最安送料を取得する" do
  it "一番安い送料を取得できる" do
    let
      userId = UserId "userId"
      weight = Weight 500
      postalCode = PostalCode "111-1111"
      shipment = Shipment { destinationPostalCode: postalCode, weight }
      rates = ShippingRates
        { head: ShippingRate { carrier: "配送業者X", amount: 200 }
        , tail:
            [ ShippingRate { carrier: "配送業者Y", amount: 100 }
            , ShippingRate { carrier: "配送業者Z", amount: 300 }
            ]
        }
      actual = runUseCase
        (stub $ userId :> Right postalCode)
        (stub $ shipment :> Right rates)
        userId
        weight
    actual `shouldEqual`
      Right (ShippingRate { carrier: "配送業者Y", amount: 100 })

  it "郵便番号の取得に失敗したらGetCheapestShippingRateFailedを返す" do
    runUseCase
      (const $ Left FetchPostalCodeFailed)
      (const $ Left FetchShippingRatesFailed)
      (UserId "userId")
      (Weight 500)
      `shouldEqual` Left GetCheapestShippingRateFailed

  it "郵便番号が存在しなければShippingDestinationNotFoundを返す" do
    runUseCase
      (const $ Left PostalCodeNotFound)
      (const $ Left FetchShippingRatesFailed)
      (UserId "unknown")
      (Weight 500)
      `shouldEqual` Left ShippingDestinationNotFound

  it "送料の取得に失敗したらGetCheapestShippingRateFailedを返す" do
    runUseCase
      (const $ Right $ PostalCode "111-1111")
      (const $ Left FetchShippingRatesFailed)
      (UserId "userId")
      (Weight 500)
      `shouldEqual` Left GetCheapestShippingRateFailed

runUseCase
  :: (UserId -> Either FetchPostalCodeError PostalCode)
  -> (Shipment -> Either FetchShippingRatesError ShippingRates)
  -> UserId
  -> Weight
  -> Either GetCheapestShippingRateError ShippingRate
runUseCase fetchPostalCode fetchRates userId weight = Run.extract
  $ Run.run (Run.match
      { postalCodePort: case _ of
          FetchPostalCodeByUserId value next -> next <$> pure (fetchPostalCode value)
      , shippingRatePort: case _ of
          FetchShippingRates value next -> next <$> pure (fetchRates value)
      })
  $ RunExcept.runExcept
  $ getCheapestShippingRate userId weight
