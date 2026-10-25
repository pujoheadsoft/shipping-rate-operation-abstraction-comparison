import {
  type UserApiClient,
  UserApiOperationFailedError,
  UserApiUserNotFoundError,
  type UserResponse,
} from "../gateway/user_api_client.ts";
import { fetchGet, HttpError } from "./http_client.ts";

export type UserApiEnvironment = Readonly<{
  baseUrl: string;
}>;

export const createUserApiClient = (
  environment: UserApiEnvironment,
): UserApiClient => ({
  fetchUser: (userId) => performFetchUser(environment, userId),
});

const performFetchUser = async (
  environment: UserApiEnvironment,
  userId: string,
): Promise<UserResponse> => {
  try {
    const body = await fetchGet(`${environment.baseUrl}/users/${userId}`);
    return JSON.parse(body) as UserResponse;
  } catch (cause) {
    if (cause instanceof HttpError && cause.status === 404) {
      throw new UserApiUserNotFoundError();
    }
    throw new UserApiOperationFailedError();
  }
};
