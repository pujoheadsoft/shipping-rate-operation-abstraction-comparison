module test/gateway/postal-code-gateway-test

import test/assert
import domain/postal-code
import domain/user-id
import usecase/postal-code-port
import gateway/postal-code-gateway
import gateway/user-api-client

pub fun test-fetch-postal-code() : ()
  val actual =
    with fun gateway/user-api-client/fetch-user(request)
      assert-equals("ユーザーIDからリクエストを生成する", User-request("userId"), request)
      Ok(User-response("111-1111"))
    fetch-postal-code(User-id("userId"))

  assert-equals("ユーザーの郵便番号を返す", Ok(Postal-code("111-1111")), actual)

pub fun test-fetch-postal-code-returns-postal-code-not-found() : ()
  val actual =
    with fun gateway/user-api-client/fetch-user(_request)
      Error(UserApiUserNotFound)
    fetch-postal-code(User-id("unknown"))

  assert-equals("郵便番号が見つからなければPostalCodeNotFoundを返す", Error(PostalCodeNotFound), actual)

pub fun test-fetch-postal-code-fails-when-user-api-fails() : ()
  val actual =
    with fun gateway/user-api-client/fetch-user(_request)
      Error(UserApiOperationFailed)
    fetch-postal-code(User-id("userId"))

  assert-equals("ユーザーAPIの失敗をFetchPostalCodeFailedに変換する", Error(FetchPostalCodeFailed), actual)
