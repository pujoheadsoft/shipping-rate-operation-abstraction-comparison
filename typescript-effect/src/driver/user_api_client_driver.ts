import { Context, Effect, Layer } from "effect";
import {
  UserApiClient,
  UserApiOperationFailed,
  UserApiUserNotFound,
  type UserRequest,
  type UserResponse,
} from "../gateway/user_api_client.ts";
import { decodeJson } from "./decode_json.ts";
import { HttpClient } from "./http_client.ts";

export class UserApiEnvironment extends Context.Service<UserApiEnvironment, Readonly<{ baseUrl: string }>>()(
  "rates/driver/UserApiEnvironment",
) {}

export const UserApiClientLive: Layer.Layer<UserApiClient, never, UserApiEnvironment | HttpClient> = Layer.effect(
  UserApiClient,
  Effect.gen(function* () {
    const environment = yield* UserApiEnvironment;
    const httpClient = yield* HttpClient;

    return {
      fetchUser: (request: UserRequest) =>
        performFetchUser(request).pipe(
          Effect.provideService(UserApiEnvironment, environment),
          Effect.provideService(HttpClient, httpClient),
        ),
    } satisfies Context.Service.Shape<typeof UserApiClient>;
  }),
);

const performFetchUser = (
  request: UserRequest,
): Effect.Effect<UserResponse, UserApiUserNotFound | UserApiOperationFailed, UserApiEnvironment | HttpClient> =>
  Effect.gen(function* () {
    const environment = yield* UserApiEnvironment;
    const httpClient = yield* HttpClient;
    const response = yield* httpClient
      .get(`${environment.baseUrl}/users/${request.userId}`)
      .pipe(Effect.mapError(() => new UserApiOperationFailed()));

    if (response.status === 404) return yield* Effect.fail(new UserApiUserNotFound());
    if (response.status < 200 || response.status >= 300) return yield* Effect.fail(new UserApiOperationFailed());

    return yield* decodeJson(response.body, isUserResponse, () => new UserApiOperationFailed());
  });

const isUserResponse = (value: unknown): value is UserResponse =>
  typeof value === "object" && value !== null && typeof (value as UserResponse).postalCode === "string";
