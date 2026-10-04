module driver/carrier-x-http-client-driver

import std/async
import effect/ask
import gateway/http-types
import gateway/carrier-x-http-client
import driver/http-client

pub struct carrier-x-http-environment(base-url : string)

pub fun with-carrier-x-http-client(
  environment : carrier-x-http-environment,
  action : () -> <carrier-x-http-client,async|e> a
) : <async|e> a
  with handler
    fun gateway/carrier-x-http-client/post(request)
      with fun ask() environment
      to-http-result(fn () perform-post(request))
  action()

fun perform-post(request : http-request)
  : <ask<carrier-x-http-environment>,async,exn> http-response
  val environment : carrier-x-http-environment = ask()
  yield()
  Http-response(200, [("amount", "1000"), ("serviceCode", "CarrierX")])
