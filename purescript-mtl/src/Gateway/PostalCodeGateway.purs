module Gateway.PostalCodeGateway
  ( Dependencies
  , createPostalCodePort
  , fetchPostalCode
  ) where

import Prelude

import Control.Monad.Except.Trans (ExceptT(..), runExceptT)
import Control.Monad.Reader.Trans (ReaderT(..), runReaderT)
import Data.Bifunctor (lmap)
import Data.Either (Either)
import Domain.PostalCode (PostalCode(..))
import Domain.UserId (UserId(..))
import Effect.Aff (Aff)
import Gateway.UserApiClient
  ( UserApiClient
  , UserApiError(..)
  , UserRequest
  , UserResponse
  )
import UseCase.PostalCodePort
  ( FetchPostalCodeError(..)
  , PostalCodePort
  )

type Dependencies =
  { userApiClient :: UserApiClient
  }

fetchPostalCode
  :: UserId
  -> ReaderT Dependencies
       (ExceptT FetchPostalCodeError Aff)
       PostalCode
fetchPostalCode =
  toUserRequest
    >>> fetchUser
    >>> map toPostalCode
  where
  toUserRequest :: UserId -> UserRequest
  toUserRequest (UserId id) = { id }

  fetchUser :: UserRequest -> ReaderT Dependencies (ExceptT FetchPostalCodeError Aff) UserResponse
  fetchUser request = ReaderT $
    _.userApiClient >>> _.fetchUser >>> (_ $ request) >>> liftUserApiResult

  liftUserApiResult
    :: Aff (Either UserApiError UserResponse)
    -> ExceptT FetchPostalCodeError Aff UserResponse
  liftUserApiResult action =
    ExceptT $ lmap toFetchPostalCodeError <$> action

  toFetchPostalCodeError :: UserApiError -> FetchPostalCodeError
  toFetchPostalCodeError UserApiUserNotFound = PostalCodeNotFound
  toFetchPostalCodeError UserApiOperationFailed = FetchPostalCodeFailed

  toPostalCode :: UserResponse -> PostalCode
  toPostalCode response = PostalCode response.postalCode

runFetchPostalCode
  :: Dependencies
  -> UserId
  -> Aff (Either FetchPostalCodeError PostalCode)
runFetchPostalCode dependencies =
  fetchPostalCode
    >>> flip runReaderT dependencies
    >>> runExceptT

createPostalCodePort :: Dependencies -> PostalCodePort
createPostalCodePort dependencies =
  { fetchPostalCodeByUserId: runFetchPostalCode dependencies
  }
