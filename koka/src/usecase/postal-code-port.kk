module usecase/postal-code-port

import domain/user-id
import domain/postal-code

pub effect postal-code-port
  fun fetch-postal-code-by-user-id(user-id : user-id) : result<postal-code,fetch-postal-code-error>

pub type fetch-postal-code-error
  PostalCodeNotFound
  FetchPostalCodeFailed

pub fun fetch-postal-code-error/show(error : fetch-postal-code-error)
  match error
    PostalCodeNotFound -> "PostalCodeNotFound"
    FetchPostalCodeFailed -> "FetchPostalCodeFailed"

pub fun fetch-postal-code-error/(==)(
  a : fetch-postal-code-error,
  b : fetch-postal-code-error
) : bool
  match (a, b)
    (PostalCodeNotFound, PostalCodeNotFound) -> True
    (FetchPostalCodeFailed, FetchPostalCodeFailed) -> True
    _ -> False
