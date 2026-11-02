{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierXApiClientDriver
  ( CarrierXApiEnvironment (..)
  , runCarrierXApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor            (first)
import           Driver.DriverError
import           Driver.HttpClient         (postJson)
import           Gateway.CarrierXApiClient
import           GHC.Generics              (Generic)
import           Polysemy
import           Polysemy.Error            (Error, runError)
import           Polysemy.Reader           (Reader, ask, runReader)

newtype CarrierXApiEnvironment = CarrierXApiEnvironment
  { baseUrl :: String
  }

data CarrierXRateResponseJson = CarrierXRateResponseJson
  { amount      :: Int
  , serviceCode :: String
  } deriving (Generic)

instance FromJSON CarrierXRateResponseJson

runCarrierXApiClient
  :: Member (Embed IO) r
  => CarrierXApiEnvironment
  -> Sem (CarrierXApiClient ': r) a
  -> Sem r a
runCarrierXApiClient environment = interpret \case
  FetchRateX request -> do
    result <- runError @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierXApiOperationFailed) result

performFetchRate
  :: Members
       '[ Reader CarrierXApiEnvironment
        , Error DriverError
        , Embed IO
        ] r
  => CarrierXRateRequest
  -> Sem r CarrierXRateResponse
performFetchRate request = do
  CarrierXApiEnvironment environmentBaseUrl <- ask
  toCarrierXRateResponse <$> postJson
      environmentBaseUrl
      "/shipping-rates"
      (encodeRateRequest request)

encodeRateRequest :: CarrierXRateRequest -> Value
encodeRateRequest request = object
  [ "destination" .= destination request
  , "weightGrams" .= weightGrams request
  ]

toCarrierXRateResponse :: CarrierXRateResponseJson -> CarrierXRateResponse
toCarrierXRateResponse (CarrierXRateResponseJson responseAmount responseServiceCode) =
  CarrierXRateResponse responseAmount responseServiceCode
