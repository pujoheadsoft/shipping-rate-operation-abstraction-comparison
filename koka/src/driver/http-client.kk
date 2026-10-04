module driver/http-client

import std/async
import driver/http-types

pub fun post(_url : string, _body : http-body) : <async,exn> http-response
  yield()
  Http-response(200, [])
