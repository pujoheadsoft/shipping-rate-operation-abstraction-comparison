{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierZApiClientDriver
  ( CarrierZApiEnvironment (..)
  , runCarrierZApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor             (first)
import           Driver.DriverError
import           Driver.HttpClient          (postJson)
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effectful.Error.Static     (Error, runErrorNoCallStack)
import           Effectful.Reader.Static    (Reader, ask, runReader)
import           Gateway.CarrierZApiClient
import           GHC.Generics               (Generic)

newtype CarrierZApiEnvironment = CarrierZApiEnvironment
  { baseUrl :: String
  }

data CarrierZRateResponseJson = CarrierZRateResponseJson
  { amount      :: Int
  , serviceCode :: String
  } deriving (Generic)

instance FromJSON CarrierZRateResponseJson

runCarrierZApiClient
  :: IOE :> es
  => CarrierZApiEnvironment
  -> Eff (CarrierZApiClient : es) a
  -> Eff es a
runCarrierZApiClient environment = interpret $ \_ -> \case
  FetchRateZ request -> do
    result <- runErrorNoCallStack @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierZApiOperationFailed) result

performFetchRate
  :: ( Reader CarrierZApiEnvironment :> es
     , Error DriverError :> es
     , IOE :> es
     )
  => CarrierZRateRequest
  -> Eff es CarrierZRateResponse
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
