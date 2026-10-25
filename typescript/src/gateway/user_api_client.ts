import type { PostalCode } from "../domain/postal_code.ts";
import type { UserId } from "../domain/user_id.ts";

export type UserResponse = Readonly<{
  postalCode: PostalCode;
}>;

export type UserApiClient = Readonly<{
  fetchUser: (userId: UserId) => Promise<UserResponse>;
}>;

export class UserApiUserNotFoundError extends Error {
  constructor() {
    super("User not found");
    this.name = "UserApiUserNotFoundError";
  }
}

export class UserApiOperationFailedError extends Error {
  constructor() {
    super("User API operation failed");
    this.name = "UserApiOperationFailedError";
  }
}
