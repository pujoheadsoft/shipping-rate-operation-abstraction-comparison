{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierYApiClientDriver
  ( CarrierYApiEnvironment (..)
  , runCarrierYApiClient
  ) where

import           Data.Aeson
import           Data.Aeson.Types           (parseEither)
import           Data.Bifunctor             (first)
import           Driver.DriverError
import           Driver.HttpClient          (postJson)
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effectful.Error.Static     (Error, runErrorNoCallStack,
                                             throwError)
import           Effectful.Reader.Static    (Reader, ask, runReader)
import           Gateway.CarrierYApiClient

newtype CarrierYApiEnvironment = CarrierYApiEnvironment
  { baseUrl :: String
  }

runCarrierYApiClient
  :: IOE :> es
  => CarrierYApiEnvironment
  -> Eff (CarrierYApiClient : es) a
  -> Eff es a
runCarrierYApiClient environment = interpret $ \_ -> \case
  FetchRateY request -> do
    result <- runErrorNoCallStack @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierYApiOperationFailed) result

performFetchRate
  :: ( Reader CarrierYApiEnvironment :> es
     , Error DriverError :> es
     , IOE :> es
     )
  => CarrierYRateRequest
  -> Eff es CarrierYRateResponse
performFetchRate request = do
  environment <- ask @CarrierYApiEnvironment
  response <- postJson
    (baseUrl environment)
    "/rates/quote"
    (encodeRateRequest request)
  either (const $ throwError DriverOperationFailed) pure
    $ decodeRateResponse response

encodeRateRequest :: CarrierYRateRequest -> Value
encodeRateRequest request = object
  [ "postalCode" .= postalCode request
  , "weight" .= weight request
  ]

decodeRateResponse :: Value -> Either String CarrierYRateResponse
decodeRateResponse = parseEither
  $ withObject "CarrierYRateResponse"
  $ \value ->
      CarrierYRateResponse
        <$> value .: "price"
        <*> value .: "serviceName"
