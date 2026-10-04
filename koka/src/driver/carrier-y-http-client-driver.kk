module driver/carrier-y-http-client-driver

import std/async
import effect/ask
import gateway/http-types
import gateway/carrier-y-http-client
import driver/http-client

pub struct carrier-y-http-environment(base-url : string)

pub fun with-carrier-y-http-client(
  environment : carrier-y-http-environment,
  action : () -> <carrier-y-http-client,async|e> a
) : <async|e> a
  with handler
    fun gateway/carrier-y-http-client/post(request)
      with fun ask() environment
      to-http-result(fn () perform-post(request))
  action()

fun perform-post(request : http-request)
  : <ask<carrier-y-http-environment>,async,exn> http-response
  val environment : carrier-y-http-environment = ask()
  yield()
  Http-response(200, [("price", "2000"), ("serviceName", "CarrierY")])
