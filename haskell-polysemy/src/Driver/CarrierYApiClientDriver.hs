{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierYApiClientDriver
  ( CarrierYApiEnvironment (..)
  , runCarrierYApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor            (first)
import           Driver.DriverError
import           Driver.HttpClient         (postJson)
import           Gateway.CarrierYApiClient
import           GHC.Generics              (Generic)
import           Polysemy
import           Polysemy.Error            (Error, runError)
import           Polysemy.Reader           (Reader, ask, runReader)

newtype CarrierYApiEnvironment = CarrierYApiEnvironment
  { baseUrl :: String
  }

data CarrierYRateResponseJson = CarrierYRateResponseJson
  { price       :: Int
  , serviceName :: String
  } deriving (Generic)

instance FromJSON CarrierYRateResponseJson

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
  CarrierYApiEnvironment environmentBaseUrl <- ask
  toCarrierYRateResponse <$> postJson
      environmentBaseUrl
      "/rates/quote"
      (encodeRateRequest request)

encodeRateRequest :: CarrierYRateRequest -> Value
encodeRateRequest request = object
  [ "postalCode" .= postalCode request
  , "weight" .= weight request
  ]

toCarrierYRateResponse :: CarrierYRateResponseJson -> CarrierYRateResponse
toCarrierYRateResponse (CarrierYRateResponseJson responsePrice responseServiceName) =
  CarrierYRateResponse responsePrice responseServiceName
