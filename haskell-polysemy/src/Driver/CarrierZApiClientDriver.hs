{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierZApiClientDriver
  ( CarrierZApiEnvironment (..)
  , runCarrierZApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor            (first)
import           Driver.DriverError
import           Driver.HttpClient         (postJson)
import           Gateway.CarrierZApiClient
import           GHC.Generics              (Generic)
import           Polysemy
import           Polysemy.Error            (Error, runError)
import           Polysemy.Reader           (Reader, ask, runReader)

newtype CarrierZApiEnvironment = CarrierZApiEnvironment
  { baseUrl :: String
  }

data CarrierZRateResponseJson = CarrierZRateResponseJson
  { amount      :: Int
  , serviceCode :: String
  } deriving (Generic)

instance FromJSON CarrierZRateResponseJson

runCarrierZApiClient
  :: Member (Embed IO) r
  => CarrierZApiEnvironment
  -> Sem (CarrierZApiClient ': r) a
  -> Sem r a
runCarrierZApiClient environment = interpret \case
  FetchRateZ request -> do
    result <- runError @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierZApiOperationFailed) result

performFetchRate
  :: Members
       '[ Reader CarrierZApiEnvironment
        , Error DriverError
        , Embed IO
        ] r
  => CarrierZRateRequest
  -> Sem r CarrierZRateResponse
performFetchRate request = do
  CarrierZApiEnvironment environmentBaseUrl <- ask
  toCarrierZRateResponse <$> postJson
      environmentBaseUrl
      "/shipping/quote"
      (encodeRateRequest request)

encodeRateRequest :: CarrierZRateRequest -> Value
encodeRateRequest request = object
  [ "postalCode" .= postalCode request
  , "weight" .= weight request
  ]

toCarrierZRateResponse :: CarrierZRateResponseJson -> CarrierZRateResponse
toCarrierZRateResponse (CarrierZRateResponseJson responseAmount responseServiceCode) =
  CarrierZRateResponse responseAmount responseServiceCode
