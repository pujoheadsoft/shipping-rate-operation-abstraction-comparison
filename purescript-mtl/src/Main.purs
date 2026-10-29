module Main (main) where

import Prelude

import Control.Monad.Except.Trans (runExceptT)
import Control.Monad.Reader.Trans (runReaderT)
import Data.Either (Either(..))
import Data.Maybe (fromMaybe)
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
import Node.Process (lookupEnv)
import UseCase.GetCheapestShippingRate
  ( GetCheapestShippingRateError(..)
  , getCheapestShippingRate
  )

main :: Effect Unit
main = do
  userApiBaseUrl <- getEnv "USER_API_BASE_URL" "http://localhost:8081"
  carrierXApiBaseUrl <- getEnv "CARRIER_X_API_BASE_URL" "http://localhost:8082"
  carrierYApiBaseUrl <- getEnv "CARRIER_Y_API_BASE_URL" "http://localhost:8083"
  carrierZApiBaseUrl <- getEnv "CARRIER_Z_API_BASE_URL" "http://localhost:8084"
  launchAff_ do
    let
      shippingRatesDependencies =
        { carrierXApiClient: createCarrierXApiClient $ CarrierXApiEnvironment
            { baseUrl: carrierXApiBaseUrl
            }
        , carrierYApiClient: createCarrierYApiClient $ CarrierYApiEnvironment
            { baseUrl: carrierYApiBaseUrl
            }
        , carrierZApiClient: createCarrierZApiClient $ CarrierZApiEnvironment
            { baseUrl: carrierZApiBaseUrl
            }
        }
      postalCodePort = createPostalCodePort
        { userApiClient: createUserApiClient $ UserApiEnvironment
            { baseUrl: userApiBaseUrl
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

getEnv :: String -> String -> Effect String
getEnv name defaultValue = fromMaybe defaultValue <$> lookupEnv name
