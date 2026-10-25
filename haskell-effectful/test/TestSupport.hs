module TestSupport (runGateway, runPostalGateway, runUseCase) where

import           Domain.PostalCode
import           Domain.Shipment
import           Domain.ShippingRate
import           Domain.ShippingRates
import           Domain.UserId
import           Domain.Weight
import           Effectful
import           Effectful.Concurrent.Async   (runConcurrent)
import           Effectful.Dispatch.Dynamic   (interpret)
import           Effectful.Error.Static
import qualified Gateway.CarrierXApiClient    as X
import qualified Gateway.CarrierYApiClient    as Y
import qualified Gateway.CarrierZApiClient    as Z
import qualified Gateway.PostalCodeGateway    as PostalGateway
import qualified Gateway.ShippingRatesGateway as Gateway
import qualified Gateway.UserApiClient        as UserApi
import           UseCase.GetCheapestShippingRate
import           UseCase.PostalCodePort
import           UseCase.ShippingRatePort

runGateway
  :: (X.CarrierXRateRequest -> IO (Either X.CarrierXApiError X.CarrierXRateResponse))
  -> (Y.CarrierYRateRequest -> IO (Either Y.CarrierYApiError Y.CarrierYRateResponse))
  -> (Z.CarrierZRateRequest -> IO (Either Z.CarrierZApiError Z.CarrierZRateResponse))
  -> Shipment
  -> IO (Either FetchShippingRatesError ShippingRates)
runGateway x y z =
  runEff
    . runErrorNoCallStack @FetchShippingRatesError
    . runConcurrent
    . interpret (\_ -> \case Z.FetchRateZ request -> liftIO $ z request)
    . interpret (\_ -> \case Y.FetchRateY request -> liftIO $ y request)
    . interpret (\_ -> \case X.FetchRateX request -> liftIO $ x request)
    . Gateway.fetchShippingRates

runPostalGateway
  :: (UserApi.UserRequest -> Either UserApi.UserApiError UserApi.UserResponse)
  -> UserId
  -> Either FetchPostalCodeError PostalCode
runPostalGateway client userId = runPureEff
  . interpret (\_ -> \case UserApi.FetchUser request -> pure $ client request)
  . PostalGateway.runPostalCodePort
  $ fetchPostalCodeByUserId userId

runUseCase
  :: (UserId -> Either FetchPostalCodeError PostalCode)
  -> (Shipment -> Either FetchShippingRatesError ShippingRates)
  -> UserId
  -> Weight
  -> Either GetCheapestShippingRateError ShippingRate
runUseCase postalCodePort shippingRatePort userId weight = runPureEff
  . runErrorNoCallStack @GetCheapestShippingRateError
  . interpret (\_ -> \case FetchShippingRates shipment -> pure $ shippingRatePort shipment)
  . interpret (\_ -> \case FetchPostalCodeByUserId requestedUserId -> pure $ postalCodePort requestedUserId)
  $ getCheapestShippingRate userId weight
