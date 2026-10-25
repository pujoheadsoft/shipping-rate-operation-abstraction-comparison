module Test.Gateway.PostalCodeGateway (spec) where

import Prelude
import Data.Either (Either(..))
import Domain.PostalCode (PostalCode(..))
import Domain.UserId (UserId(..))
import Gateway.PostalCodeGateway (fetchPostalCode)
import Gateway.UserApiClient as UserApi
import Run as Run
import Test.PMock (stub, (:>))
import Test.Spec (Spec, describe, it)
import Test.Spec.Assertions (shouldEqual)
import UseCase.PostalCodePort (FetchPostalCodeError(..))

spec :: Spec Unit
spec = describe "ユーザーIDから郵便番号を取得する" do
  it "ユーザーIDから郵便番号を取得できる" do
    let
      response = stub $ { id: "userId" } :>
        (Right { postalCode: "111-1111" }
          :: Either UserApi.UserApiError UserApi.UserResponse)
      actual = Run.extract
        $ Run.run (Run.match
            { userApiClient: case _ of
                UserApi.FetchUser request next -> next <$> pure (response request)
            })
        $ fetchPostalCode (UserId "userId")
    actual `shouldEqual` Right (PostalCode "111-1111")

  it "ユーザーが存在しなければPostalCodeNotFoundを返す" do
    let actual = Run.extract
          $ Run.run (Run.match
              { userApiClient: case _ of
                  UserApi.FetchUser _ next -> next <$> pure (Left UserApi.UserApiUserNotFound)
              })
          $ fetchPostalCode (UserId "unknown")
    actual `shouldEqual` Left PostalCodeNotFound

  it "ユーザーAPIの失敗をFetchPostalCodeFailedに変換する" do
    let actual = Run.extract
          $ Run.run (Run.match
              { userApiClient: case _ of
                  UserApi.FetchUser _ next -> next <$> pure (Left UserApi.UserApiOperationFailed)
              })
          $ fetchPostalCode (UserId "userId")
    actual `shouldEqual` Left FetchPostalCodeFailed
