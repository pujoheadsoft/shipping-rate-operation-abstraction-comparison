import { Context, Effect, Layer } from "effect";
import { FetchPostalCodeFailed, PostalCodeNotFound, PostalCodePort } from "../usecase/postal_code_port.ts";
import { UserApiClient, UserApiUserNotFound } from "./user_api_client.ts";

export const PostalCodeGatewayLive: Layer.Layer<PostalCodePort, never, UserApiClient> = Layer.effect(
  PostalCodePort,
  Effect.gen(function* () {
    const userApiClient = yield* UserApiClient;
    return {
      fetchPostalCodeByUserId: (userId) =>
        userApiClient.fetchUser({ userId }).pipe(
          Effect.map((user) => user.postalCode),
          Effect.mapError((error) =>
            error instanceof UserApiUserNotFound ? new PostalCodeNotFound() : new FetchPostalCodeFailed(),
          ),
        ),
    } satisfies Context.Service.Shape<typeof PostalCodePort>;
  }),
);
