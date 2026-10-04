module driver/carrier-z-api-client-driver

import std/async
import effect/ask
import gateway/carrier-z-api-client
import driver/http-types
import driver/http-client

pub struct carrier-z-api-environment(base-url : string)

pub fun with-carrier-z-api-client(
  environment : carrier-z-api-environment,
  action : () -> <carrier-z-api-client,async|e> a
) : <async|e> a
  with handler
    fun gateway/carrier-z-api-client/fetch-rate(request)
      with fun ask() environment
      match to-http-result(fn () perform-fetch-rate(request))
        Ok(response) -> Ok(response)
        Error(_) -> Error(CarrierZApiRequestFailed)
  action()

fun perform-fetch-rate(request : carrier-z-rate-request)
  : <ask<carrier-z-api-environment>,async,exn> carrier-z-rate-response
  val environment : carrier-z-api-environment = ask()
  val response = post(
    environment.base-url ++ "/shipping/quote",
    encode-rate-request(request)
  )
  decode-rate-response(response)

fun encode-rate-request(request : carrier-z-rate-request) : http-body
  [ ("postalCode", request.postal-code)
  , ("weight", request.weight.show)
  ]

fun decode-rate-response(_response : http-response) : carrier-z-rate-response
  Carrier-z-rate-response(3000, "CarrierZ")
