import assert from "node:assert/strict";
import { test } from "node:test";
import { Context, Effect, Layer } from "effect";
import { PostalCodeGatewayLive } from "../../src/gateway/postal_code_gateway.ts";
import { UserApiClient, UserApiOperationFailed, UserApiUserNotFound } from "../../src/gateway/user_api_client.ts";
import { FetchPostalCodeFailed, PostalCodeNotFound, PostalCodePort } from "../../src/usecase/postal_code_port.ts";

const run = (userApiClient: Context.Service.Shape<typeof UserApiClient>) =>
  PostalCodePort.use((port) => port.fetchPostalCodeByUserId("user-123")).pipe(
    Effect.provide(PostalCodeGatewayLive.pipe(Layer.provide(Layer.succeed(UserApiClient, userApiClient)))),
    Effect.match({ onFailure: (error) => error, onSuccess: (postalCode) => postalCode }),
    Effect.runPromise,
  );

test("User APIから郵便番号を取得する", async () => {
  assert.equal(await run({ fetchUser: () => Effect.succeed({ postalCode: "111-1111" }) }), "111-1111");
});

test("User未登録をPostalCodeNotFoundへ変換する", async () => {
  assert.deepEqual(await run({ fetchUser: () => Effect.fail(new UserApiUserNotFound()) }), new PostalCodeNotFound());
});

test("User API失敗をFetchPostalCodeFailedへ変換する", async () => {
  assert.deepEqual(
    await run({ fetchUser: () => Effect.fail(new UserApiOperationFailed()) }),
    new FetchPostalCodeFailed(),
  );
});
