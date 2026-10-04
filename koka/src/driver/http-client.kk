module driver/http-client

import std/async
import gateway/http-types

pub fun to-http-result(action : () -> <async,exn|e> http-response)
  : <async|e> result<http-response,http-error>
  try(
    fn (_) Error(HttpRequestFailed),
    fn () Ok(action())
  )
