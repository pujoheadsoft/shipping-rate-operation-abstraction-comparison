module UseCase.GetCheapestShippingRateSpec (spec) where

import Data.List.NonEmpty (NonEmpty (..))
import Domain.PostalCode
import Domain.Shipment
import Domain.ShippingRate
import Domain.ShippingRates
import Domain.UserId
import Domain.Weight
import Polysemy
import Polysemy.Error
import Test.Hspec
import Test.MockCat
import UseCase.GetCheapestShippingRate
import UseCase.PostalCodePort
import UseCase.ShippingRatePort

spec :: Spec
spec = describe "ユーザーの配送先に対する最安送料を取得する" do
  it "一番安い送料を取得できる" do
    let userId = UserId "userId"
        weight = Weight 500
        postalCode = PostalCode "111-1111"
        shipment = Shipment postalCode weight
        rates = ShippingRates
          ( ShippingRate "配送業者X" 200
          :| [ShippingRate "配送業者Y" 100, ShippingRate "配送業者Z" 300]
          )
    runUseCase
      (stub $ userId ~> Right postalCode)
      (stub $ shipment ~> Right rates)
      userId
      weight
      `shouldBe` Right (ShippingRate "配送業者Y" 100)

  it "郵便番号の取得に失敗したらGetCheapestShippingRateFailedを返す" do
    runUseCase
      (const $ Left FetchPostalCodeFailed)
      (const $ Left FetchShippingRatesFailed)
      (UserId "userId")
      (Weight 500)
      `shouldBe` Left GetCheapestShippingRateFailed

  it "郵便番号が存在しなければShippingDestinationNotFoundを返す" do
    runUseCase
      (const $ Left PostalCodeNotFound)
      (const $ Left FetchShippingRatesFailed)
      (UserId "unknown")
      (Weight 500)
      `shouldBe` Left ShippingDestinationNotFound

  it "送料の取得に失敗したらGetCheapestShippingRateFailedを返す" do
    runUseCase
      (const $ Right $ PostalCode "111-1111")
      (const $ Left FetchShippingRatesFailed)
      (UserId "userId")
      (Weight 500)
      `shouldBe` Left GetCheapestShippingRateFailed

runUseCase
  :: (UserId -> Either FetchPostalCodeError PostalCode)
  -> (Shipment -> Either FetchShippingRatesError ShippingRates)
  -> UserId
  -> Weight
  -> Either GetCheapestShippingRateError ShippingRate
runUseCase postalCodePort shippingRatePort userId weight = run
  . runError @GetCheapestShippingRateError
  . interpret (\case FetchShippingRates shipment -> pure $ shippingRatePort shipment)
  . interpret (\case FetchPostalCodeByUserId requestedUserId -> pure $ postalCodePort requestedUserId)
  $ getCheapestShippingRate userId weight
