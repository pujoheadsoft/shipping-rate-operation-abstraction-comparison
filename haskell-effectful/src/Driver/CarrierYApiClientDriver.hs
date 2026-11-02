{-# LANGUAGE DeriveGeneric     #-}
{-# LANGUAGE NoFieldSelectors #-}
{-# LANGUAGE OverloadedStrings #-}

module Driver.CarrierYApiClientDriver
  ( CarrierYApiEnvironment (..)
  , runCarrierYApiClient
  ) where

import           Data.Aeson
import           Data.Bifunctor             (first)
import           Driver.DriverError
import           Driver.HttpClient          (postJson)
import           Effectful
import           Effectful.Dispatch.Dynamic (interpret)
import           Effectful.Error.Static     (Error, runErrorNoCallStack)
import           Effectful.Reader.Static    (Reader, ask, runReader)
import           Gateway.CarrierYApiClient
import           GHC.Generics               (Generic)

newtype CarrierYApiEnvironment = CarrierYApiEnvironment
  { baseUrl :: String
  }

data CarrierYRateResponseJson = CarrierYRateResponseJson
  { price       :: Int
  , serviceName :: String
  } deriving (Generic)

instance FromJSON CarrierYRateResponseJson

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
