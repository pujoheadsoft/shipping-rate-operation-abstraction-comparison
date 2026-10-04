module driver/carrier-y-api-client-driver

import std/async
import effect/ask
import gateway/carrier-y-api-client
import driver/http-types
import driver/http-client

pub struct carrier-y-api-environment(base-url : string)

pub fun with-carrier-y-api-client(
  environment : carrier-y-api-environment,
  action : () -> <carrier-y-api-client,async|e> a
) : <async|e> a
  with handler
    fun gateway/carrier-y-api-client/fetch-rate(request)
      with fun ask() environment
      match to-http-result(fn () perform-fetch-rate(request))
        Ok(response) -> Ok(response)
        Error(_) -> Error(CarrierYApiRequestFailed)
  action()

fun perform-fetch-rate(request : carrier-y-rate-request)
  : <ask<carrier-y-api-environment>,async,exn> carrier-y-rate-response
  val environment : carrier-y-api-environment = ask()
  val response = post(
    environment.base-url ++ "/rates/quote",
    encode-rate-request(request)
  )
  decode-rate-response(response)

fun encode-rate-request(request : carrier-y-rate-request) : http-body
  [ ("postalCode", request.postal-code)
  , ("weight", request.weight.show)
  ]

fun decode-rate-response(_response : http-response) : carrier-y-rate-response
  Carrier-y-rate-response(2000, "CarrierY")
