module driver/carrier-z-http-client-driver

import std/async
import effect/ask
import gateway/http-types
import gateway/carrier-z-http-client
import driver/http-client

pub struct carrier-z-http-environment(base-url : string)

pub fun with-carrier-z-http-client(
  environment : carrier-z-http-environment,
  action : () -> <carrier-z-http-client,async|e> a
) : <async|e> a
  with handler
    fun gateway/carrier-z-http-client/post(request)
      with fun ask() environment
      to-http-result(fn () perform-post(request))
  action()

fun perform-post(request : http-request)
  : <ask<carrier-z-http-environment>,async,exn> http-response
  val environment : carrier-z-http-environment = ask()
  yield()
  Http-response(200, [("amount", "3000"), ("serviceCode", "CarrierZ")])
