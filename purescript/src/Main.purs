module Main (main) where

import Prelude

import Control.Monad.Reader.Trans (runReaderT)
import Data.Either (Either(..))
import Data.Foldable (traverse_)
import Domain.Shipment (Shipment(..))
import Domain.ShippingRate (ShippingRate(..))
import Domain.ShippingRates (ShippingRates(..))
import Effect (Effect)
import Effect.Aff (launchAff_)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Gateway.CarrierX (CarrierXRateResponse(..))
import Gateway.CarrierY (CarrierYRateResponse(..))
import Gateway.CarrierZ (CarrierZRateResponse(..))
import Gateway.ShippingRatesGateway (Dependencies, createShippingRatePort)
import UseCase.GetShippingRates (getShippingRates)
import UseCase.GetShippingRatesError (GetShippingRatesError(..))

main :: Effect Unit
main = launchAff_ do
  let
    dependencies =
      { fetchCarrierXRate: \_ -> pure $
          CarrierXRateResponse { amount: 1000, serviceCode: "CarrierX" }
      , fetchCarrierYRate: \_ -> pure $
          CarrierYRateResponse { price: 2000, serviceName: "CarrierY" }
      , fetchCarrierZRate: \_ -> pure $
          CarrierZRateResponse { amount: 3000, serviceCode: "CarrierZ" }
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
