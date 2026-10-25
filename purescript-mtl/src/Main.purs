module Main (main) where

import Prelude

import Control.Monad.Except.Trans (runExceptT)
import Control.Monad.Reader.Trans (runReaderT)
import Data.Either (Either(..))
import Driver.CarrierXApiClientDriver (CarrierXApiEnvironment(..), createCarrierXApiClient)
import Driver.CarrierYApiClientDriver (CarrierYApiEnvironment(..), createCarrierYApiClient)
import Driver.CarrierZApiClientDriver (CarrierZApiEnvironment(..), createCarrierZApiClient)
import Driver.UserApiClientDriver (UserApiEnvironment(..), createUserApiClient)
import Domain.ShippingRate (ShippingRate(..))
import Domain.UserId (UserId(..))
import Domain.Weight (Weight(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Gateway.PostalCodeGateway (createPostalCodePort)
import Gateway.ShippingRatesGateway (createShippingRatePort)
import UseCase.GetCheapestShippingRate
  ( GetCheapestShippingRateError(..)
  , getCheapestShippingRate
  )

main :: Effect Unit
main = launchAff_ do
  let
    shippingRatesDependencies =
      { carrierXApiClient: createCarrierXApiClient $ CarrierXApiEnvironment
          { baseUrl: "https://carrier-x.example.com"
          }
      , carrierYApiClient: createCarrierYApiClient $ CarrierYApiEnvironment
          { baseUrl: "https://carrier-y.example.com"
          }
      , carrierZApiClient: createCarrierZApiClient $ CarrierZApiEnvironment
          { baseUrl: "https://carrier-z.example.com"
          }
      }
    postalCodePort = createPostalCodePort
      { userApiClient: createUserApiClient $ UserApiEnvironment
          { baseUrl: "https://users.example.com"
          }
      }
    shippingRatePort = createShippingRatePort shippingRatesDependencies

  result <- runExceptT $ runReaderT
    (getCheapestShippingRate (UserId "user-123") (Weight 1000))
    { postalCodePort, shippingRatePort }

  liftEffect case result of
    Right rate -> do
      log "一番安い送料の取得に成功しました。"
      printShippingRate rate
    Left ShippingDestinationNotFound ->
      log "配送先が登録されていません。"
    Left GetCheapestShippingRateFailed ->
      log "一番安い送料の取得に失敗しました。"

printShippingRate :: ShippingRate -> Effect Unit
printShippingRate (ShippingRate rate) =
  log $ "  " <> rate.carrier <> ": " <> show rate.amount <> "円"
