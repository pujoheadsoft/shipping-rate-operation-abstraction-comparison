import { expect, jest, test } from "@jest/globals";
import { error, ok } from "../../src/data/result.ts";
import {
  fetchPostalCode,
  type PostalCodeGatewayDependencies,
} from "../../src/gateway/postal_code_gateway.ts";
import {
  UserApiOperationFailedError,
  UserApiUserNotFoundError,
} from "../../src/gateway/user_api_client.ts";
import {
  FetchPostalCodeFailed,
  PostalCodeNotFound,
} from "../../src/port/postal_code_error.ts";

test("ユーザーIDから郵便番号を取得できる", async () => {
  const dependencies: jest.Mocked<PostalCodeGatewayDependencies> = {
    userApiClient: { fetchUser: jest.fn() },
  };
  dependencies.userApiClient.fetchUser
    .whenCalledWith("userId")
    .mockResolvedValue({ postalCode: "111-1111" });

  const actual = await fetchPostalCode(dependencies)("userId");

  expect(actual).toEqual(ok("111-1111"));
});

test("ユーザーが存在しなければ郵便番号なしを返す", async () => {
  const dependencies: jest.Mocked<PostalCodeGatewayDependencies> = {
    userApiClient: { fetchUser: jest.fn() },
  };
  dependencies.userApiClient.fetchUser
    .whenCalledWith("unknown")
    .mockRejectedValue(new UserApiUserNotFoundError());

  const actual = await fetchPostalCode(dependencies)("unknown");

  expect(actual).toEqual(error(PostalCodeNotFound));
});

test("ユーザーAPIの失敗をFetchPostalCodeFailedに変換する", async () => {
  const dependencies: jest.Mocked<PostalCodeGatewayDependencies> = {
    userApiClient: { fetchUser: jest.fn() },
  };
  dependencies.userApiClient.fetchUser
    .whenCalledWith("userId")
    .mockRejectedValue(new UserApiOperationFailedError());

  const actual = await fetchPostalCode(dependencies)("userId");

  expect(actual).toEqual(error(FetchPostalCodeFailed));
});
