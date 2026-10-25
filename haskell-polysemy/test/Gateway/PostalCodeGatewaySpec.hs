module Gateway.PostalCodeGatewaySpec (spec) where

import Domain.PostalCode
import Domain.UserId
import Gateway.PostalCodeGateway
import Gateway.UserApiClient
import Polysemy
import Test.Hspec
import Test.MockCat
import UseCase.PostalCodePort

spec :: Spec
spec = describe "ユーザーIDから郵便番号を取得する" do
  it "ユーザーIDから郵便番号を取得できる" do
    let request = UserRequest "userId"
        client = stub (request ~> Right (UserResponse "111-1111"))
    runGateway client (UserId "userId")
      `shouldBe` Right (PostalCode "111-1111")

  it "ユーザーが存在しなければPostalCodeNotFoundを返す" do
    let client = const $ Left UserApiUserNotFound
    runGateway client (UserId "unknown") `shouldBe` Left PostalCodeNotFound

  it "ユーザーAPIの失敗をFetchPostalCodeFailedに変換する" do
    let client = const $ Left UserApiOperationFailed
    runGateway client (UserId "userId") `shouldBe` Left FetchPostalCodeFailed

runGateway
  :: (UserRequest -> Either UserApiError UserResponse)
  -> UserId
  -> Either FetchPostalCodeError PostalCode
runGateway client userId = run
  . interpret (\case FetchUser request -> pure $ client request)
  . runPostalCodePort
  $ fetchPostalCodeByUserId userId
