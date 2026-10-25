module driver/http-client

import std/async
import driver/http-types

pub fun get(_url : string) : <async,exn> http-response
  yield()
  Http-response(200, [])

pub fun post(_url : string, _body : http-body) : <async,exn> http-response
  yield()
  Http-response(200, [])
