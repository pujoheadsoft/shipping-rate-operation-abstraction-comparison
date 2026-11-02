{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierXApiClientDriver
  ( CarrierXApiEnvironment (..)
  , runCarrierXApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor             (first)
import           Driver.DriverError
import           Driver.HttpClient          (postJson)
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effectful.Error.Static     (Error, runErrorNoCallStack)
import           Effectful.Reader.Static    (Reader, ask, runReader)
import           Gateway.CarrierXApiClient
import           GHC.Generics               (Generic)

newtype CarrierXApiEnvironment = CarrierXApiEnvironment
  { baseUrl :: String
  }

data CarrierXRateResponseJson = CarrierXRateResponseJson
  { amount      :: Int
  , serviceCode :: String
  } deriving (Generic)

instance FromJSON CarrierXRateResponseJson

runCarrierXApiClient
  :: IOE :> es
  => CarrierXApiEnvironment
  -> Eff (CarrierXApiClient : es) a
  -> Eff es a
runCarrierXApiClient environment = interpret $ \_ -> \case
  FetchRateX request -> do
    result <- runErrorNoCallStack @DriverError
      $ runReader environment
      $ performFetchRate request
    pure $ first (const CarrierXApiOperationFailed) result

performFetchRate
  :: ( Reader CarrierXApiEnvironment :> es
     , Error DriverError :> es
     , IOE :> es
     )
  => CarrierXRateRequest
  -> Eff es CarrierXRateResponse
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
