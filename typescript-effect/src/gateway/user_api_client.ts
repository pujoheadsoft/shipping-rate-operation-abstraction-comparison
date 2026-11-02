import { Context, type Effect } from "effect";
import type { PostalCode } from "../domain/postal_code.ts";
import type { UserId } from "../domain/user_id.ts";

export type UserRequest = Readonly<{ userId: UserId }>;
export type UserResponse = Readonly<{ postalCode: PostalCode }>;

export class UserApiUserNotFound {
  readonly _tag = "UserApiUserNotFound";
}

export class UserApiOperationFailed {
  readonly _tag = "UserApiOperationFailed";
}

export class UserApiClient extends Context.Service<
  UserApiClient,
  {
    readonly fetchUser: (
      request: UserRequest,
    ) => Effect.Effect<UserResponse, UserApiUserNotFound | UserApiOperationFailed>;
  }
>()("rates/gateway/UserApiClient") {}
