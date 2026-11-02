import { Context, type Effect } from "effect";
import type { PostalCode } from "../domain/postal_code.ts";
import type { UserId } from "../domain/user_id.ts";

export class PostalCodeNotFound {
  readonly _tag = "PostalCodeNotFound";
}

export class FetchPostalCodeFailed {
  readonly _tag = "FetchPostalCodeFailed";
}

export class PostalCodePort extends Context.Service<
  PostalCodePort,
  {
    readonly fetchPostalCodeByUserId: (
      userId: UserId,
    ) => Effect.Effect<PostalCode, PostalCodeNotFound | FetchPostalCodeFailed>;
  }
>()("rates/usecase/PostalCodePort") {}
