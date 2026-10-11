import { Effect } from "effect";

export const decodeJson = <A, E>(
  body: string,
  isA: (value: unknown) => value is A,
  onError: () => E,
): Effect.Effect<A, E> =>
  Effect.try({
    try: () => JSON.parse(body) as unknown,
    catch: onError,
  }).pipe(Effect.flatMap((value) => (isA(value) ? Effect.succeed(value) : Effect.fail(onError()))));
