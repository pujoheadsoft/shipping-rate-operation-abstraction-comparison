import type { Result } from "../data/result.ts";
import type { PostalCode } from "../domain/postal_code.ts";
import type { UserId } from "../domain/user_id.ts";
import type { FetchPostalCodeError } from "./postal_code_error.ts";

export type PostalCodePort = Readonly<{
  fetchPostalCodeByUserId: (
    userId: UserId,
  ) => Promise<Result<FetchPostalCodeError, PostalCode>>;
}>;
