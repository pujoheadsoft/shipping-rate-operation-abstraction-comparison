module Main (main) where

import Prelude

import Control.Monad.Reader.Trans (runReaderT)
import Data.Either (Either(..))
import Data.Foldable (traverse_)
import Driver.CarrierXApiClientDriver (CarrierXApiEnvironment(..), createCarrierXApiClient)
import Driver.CarrierYApiClientDriver (CarrierYApiEnvironment(..), createCarrierYApiClient)
import Driver.CarrierZApiClientDriver (CarrierZApiEnvironment(..), createCarrierZApiClient)
import Driver.HttpClient (fetchPost)
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Gateway.ShippingRatesGateway (Dependencies, createShippingRatePort)
import UseCase.GetShippingRates (GetShippingRatesError(..), getShippingRates)

main :: Effect Unit
main = launchAff_ do
  let
    dependencies =
      { carrierXApiClient: createCarrierXApiClient $ CarrierXApiEnvironment
          { baseUrl: "https://carrier-x.example.com"
          , post: fetchPost
          }
      , carrierYApiClient: createCarrierYApiClient $ CarrierYApiEnvironment
          { baseUrl: "https://carrier-y.example.com"
          , post: fetchPost
          }
      , carrierZApiClient: createCarrierZApiClient $ CarrierZApiEnvironment
          { baseUrl: "https://carrier-z.example.com"
          , post: fetchPost
          }
      } :: Dependencies
    shipment = Shipment { destinationPostalCode: "111-1111", weight: 1000 }
    port = createShippingRatePort dependencies

  result <- runReaderT (getShippingRates shipment) port

  liftEffect case result of
    Right rates -> printShippingRates rates
    Left GetShippingRatesFailed ->
      log "送料の取得に失敗しました。配送業者から送料を取得できませんでした。"

printShippingRates :: ShippingRates -> Effect Unit
printShippingRates (ShippingRates rates) = do
  log "送料の取得に成功しました。"
  traverse_ printShippingRate rates

printShippingRate :: ShippingRate -> Effect Unit
printShippingRate (ShippingRate rate) =
  log $ "  " <> rate.carrier <> ": " <> show rate.amount <> "円"
