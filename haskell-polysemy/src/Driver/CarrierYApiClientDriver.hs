{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierYApiClientDriver
  ( CarrierYApiEnvironment (..)
  , runCarrierYApiClient
  ) where

import           Data.Aeson
import           Data.Aeson.Types          (parseEither)
import           Data.Bifunctor            (first)
import           Driver.DriverError
import           Driver.HttpClient         (postJson)
import           Gateway.CarrierYApiClient
import           Polysemy
import           Polysemy.Error            (Error, runError, throw)
import           Polysemy.Reader           (Reader, ask, runReader)

newtype CarrierYApiEnvironment = CarrierYApiEnvironment
  { baseUrl :: String
  }

runCarrierYApiClient
  :: Member (Embed IO) r
  => CarrierYApiEnvironment
  -> Sem (CarrierYApiClient ': r) a
  -> Sem r a
runCarrierYApiClient environment = interpret \case
  FetchRateY request -> do
    result <- runError @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierYApiOperationFailed) result

performFetchRate
  :: Members
       '[ Reader CarrierYApiEnvironment
        , Error DriverError
        , Embed IO
        ] r
  => CarrierYRateRequest
  -> Sem r CarrierYRateResponse
performFetchRate request = do
  environment <- ask @CarrierYApiEnvironment
  response <- postJson
    (baseUrl environment)
    "/rates/quote"
    (encodeRateRequest request)
  either (const $ throw DriverOperationFailed) pure
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
