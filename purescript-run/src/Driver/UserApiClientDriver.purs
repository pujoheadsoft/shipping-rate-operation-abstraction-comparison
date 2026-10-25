module Driver.UserApiClientDriver
  ( UserApiEnvironment
  , runUserApiClient
  ) where

import Prelude
import Data.Bifunctor (lmap)
import Driver.HttpClient (fetchGet)
import Effect.Aff (attempt)
import Gateway.UserApiClient as UserApi
import Run (AFF, Run)
import Run as Run
import Run.Except as RunExcept
import Run.Reader as RunReader
import Type.Row (type (+))
import Yoga.JSON (readJSON)

type UserApiEnvironment = { baseUrl :: String }

runUserApiClient
  :: forall r
   . UserApiEnvironment
  -> Run (AFF + (userApiClient :: UserApi.USER_API_CLIENT | r))
  ~> Run (AFF + r)
runUserApiClient environment run = Run.interpret
  (Run.on UserApi._userApiClient (userApiClientHandler environment) Run.send)
  run

userApiClientHandler
  :: forall r
   . UserApiEnvironment
  -> UserApi.UserApiClientF
  ~> Run (AFF + r)
userApiClientHandler environment = case _ of
  UserApi.FetchUser request next -> do
    result <- performFetchUser request
      # RunReader.runReader environment
      # RunExcept.runExcept
    pure $ next result

performFetchUser
  :: forall r
   . UserApi.UserRequest
  -> Run
       ( RunReader.READER UserApiEnvironment
       + RunExcept.EXCEPT UserApi.UserApiError
       + AFF
       + r
       )
       UserApi.UserResponse
performFetchUser request = do
  environment <- RunReader.ask
  attemptedResponse <- Run.liftAff
    $ attempt
    $ fetchGet
    $ environment.baseUrl <> "/users/" <> request.id
  response <- RunExcept.rethrow
    $ lmap (const UserApi.UserApiOperationFailed) attemptedResponse
  if response.status == 404 then
    RunExcept.throw UserApi.UserApiUserNotFound
  else if not response.ok then
    RunExcept.throw UserApi.UserApiOperationFailed
  else do
    attemptedBody <- Run.liftAff $ attempt response.text
    body <- RunExcept.rethrow
      $ lmap (const UserApi.UserApiOperationFailed) attemptedBody
    RunExcept.rethrow
      $ lmap (const UserApi.UserApiOperationFailed)
      $ readJSON body
