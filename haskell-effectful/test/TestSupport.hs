module TestSupport (runGateway, runUseCase) where

import           Domain.Shipment
import           Domain.ShippingRates
import           Effectful
import           Effectful.Concurrent.Async   (runConcurrent)
import           Effectful.Dispatch.Dynamic   (interpret)
import           Effectful.Error.Static
import qualified Gateway.CarrierXApiClient    as X
import qualified Gateway.CarrierYApiClient    as Y
import qualified Gateway.CarrierZApiClient    as Z
import qualified Gateway.ShippingRatesGateway as Gateway
import           UseCase.GetShippingRates
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

runUseCase
  :: (Shipment -> IO (Either FetchShippingRatesError ShippingRates))
  -> Shipment
  -> IO (Either GetShippingRatesError ShippingRates)
runUseCase port =
  runEff
    . runErrorNoCallStack @GetShippingRatesError
    . interpret (\_ -> \case FetchShippingRates shipment -> liftIO $ port shipment)
    . getShippingRates
