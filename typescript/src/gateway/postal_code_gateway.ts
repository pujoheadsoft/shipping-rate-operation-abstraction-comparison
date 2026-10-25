import { error, ok, type Result } from "../data/result.ts";
import type { PostalCode } from "../domain/postal_code.ts";
import type { UserId } from "../domain/user_id.ts";
import {
  FetchPostalCodeFailed,
  type FetchPostalCodeError,
  PostalCodeNotFound,
} from "../port/postal_code_error.ts";
import type { PostalCodePort } from "../port/postal_code_port.ts";
import {
  type UserApiClient,
  UserApiUserNotFoundError,
} from "./user_api_client.ts";

export type PostalCodeGatewayDependencies = Readonly<{
  userApiClient: UserApiClient;
}>;

type FetchPostalCodeResult = Result<FetchPostalCodeError, PostalCode>;

export const fetchPostalCode = (
  dependencies: PostalCodeGatewayDependencies,
) => async (userId: UserId): Promise<FetchPostalCodeResult> => {
  try {
    const user = await dependencies.userApiClient.fetchUser(userId);
    return ok(user.postalCode);
  } catch (cause) {
    return cause instanceof UserApiUserNotFoundError
      ? error(PostalCodeNotFound)
      : error(FetchPostalCodeFailed);
  }
};

export const createPostalCodePort = (
  dependencies: PostalCodeGatewayDependencies,
): PostalCodePort => ({
  fetchPostalCodeByUserId: fetchPostalCode(dependencies),
});
