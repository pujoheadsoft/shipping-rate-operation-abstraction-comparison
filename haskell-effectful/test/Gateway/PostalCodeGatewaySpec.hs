module Gateway.PostalCodeGatewaySpec (spec) where

import Domain.PostalCode
import Domain.UserId
import Gateway.UserApiClient
import Test.Hspec
import Test.MockCat
import TestSupport (runPostalGateway)
import UseCase.PostalCodePort

spec :: Spec
spec = describe "ユーザーIDから郵便番号を取得する" do
  it "ユーザーIDから郵便番号を取得できる" do
    let request = UserRequest "userId"
        client = stub $ request ~> Right (UserResponse "111-1111")
    runPostalGateway client (UserId "userId")
      `shouldBe` Right (PostalCode "111-1111")

  it "ユーザーが存在しなければPostalCodeNotFoundを返す" do
    runPostalGateway (const $ Left UserApiUserNotFound) (UserId "unknown")
      `shouldBe` Left PostalCodeNotFound

  it "ユーザーAPIの失敗をFetchPostalCodeFailedに変換する" do
    runPostalGateway (const $ Left UserApiOperationFailed) (UserId "userId")
      `shouldBe` Left FetchPostalCodeFailed
