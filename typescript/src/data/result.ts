export type Result<E, A> =
  | Readonly<{ type: "ok"; value: A }>
  | Readonly<{ type: "error"; error: E }>;

export const ok = <A>(value: A): Result<never, A> => ({ type: "ok", value });

export const error = <E>(value: E): Result<E, never> => ({
  type: "error",
  error: value,
});
