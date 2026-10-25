export const PostalCodeNotFound = "PostalCodeNotFound" as const;
export const FetchPostalCodeFailed = "FetchPostalCodeFailed" as const;

export type FetchPostalCodeError =
  | typeof PostalCodeNotFound
  | typeof FetchPostalCodeFailed;
