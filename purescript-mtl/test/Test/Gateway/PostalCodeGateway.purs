module Test.Gateway.PostalCodeGateway (spec) where

import Prelude

import Control.Monad.Except.Trans (runExceptT)
import Control.Monad.Reader.Trans (runReaderT)
import Data.Either (Either(..))
import Domain.PostalCode (PostalCode(..))
import Domain.UserId (UserId(..))
import Effect.Aff (Aff)
import Gateway.PostalCodeGateway (Dependencies, fetchPostalCode)
import Gateway.UserApiClient (UserApiError(..), UserRequest, UserResponse)
import Test.PMock (stub, (:>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import UseCase.PostalCodePort (FetchPostalCodeError(..))

spec :: Spec Unit
spec = describe "ユーザーIDから郵便番号を取得する" do
  it "ユーザーIDから郵便番号を取得できる" do
    let
      request = { id: "userId" } :: UserRequest
      response = { postalCode: "111-1111" } :: UserResponse
      dependencies =
        { userApiClient:
            { fetchUser: stub $ request :>
                (pure (Right response) :: Aff (Either UserApiError UserResponse))
            }
        } :: Dependencies

    actual <- runExceptT $ runReaderT
      (fetchPostalCode $ UserId "userId")
      dependencies

    actual `shouldEqual` Right (PostalCode "111-1111")

  it "ユーザーが存在しなければ郵便番号なしを返す" do
    let
      request = { id: "unknown" } :: UserRequest
      dependencies =
        { userApiClient:
            { fetchUser: stub $ request :>
                (pure (Left UserApiUserNotFound) :: Aff (Either UserApiError UserResponse))
            }
        } :: Dependencies

    actual <- runExceptT $ runReaderT
      (fetchPostalCode $ UserId "unknown")
      dependencies

    actual `shouldEqual` Left PostalCodeNotFound

  it "ユーザーAPIの失敗を郵便番号取得エラーに変換する" do
    let
      request = { id: "userId" } :: UserRequest
      dependencies =
        { userApiClient:
            { fetchUser: stub $ request :>
                (pure (Left UserApiOperationFailed) :: Aff (Either UserApiError UserResponse))
            }
        } :: Dependencies

    actual <- runExceptT $ runReaderT
      (fetchPostalCode $ UserId "userId")
      dependencies

    actual `shouldEqual` Left FetchPostalCodeFailed
