module driver/http-client

import std/async
import driver/http-types

pub fun post(_url : string, _body : http-body) : <async,exn> http-response
  yield()
  Http-response(200, [])

pub fun to-http-result(action : () -> <async,exn|e> a)
  : <async|e> result<a,http-error>
  try(
    fn (_) Error(HttpRequestFailed),
    fn () Ok(action())
  )
