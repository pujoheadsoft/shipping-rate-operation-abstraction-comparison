module driver/carrier-x-api-client-driver

import std/async
import effect/ask
import gateway/carrier-x-api-client
import driver/http-types
import driver/http-client

pub struct carrier-x-api-environment(base-url : string)

pub fun with-carrier-x-api-client(
  environment : carrier-x-api-environment,
  action : () -> <carrier-x-api-client,async|e> a
) : <async|e> a
  with handler
    fun gateway/carrier-x-api-client/fetch-rate(request)
      with fun ask() environment
      match to-http-result(fn () perform-fetch-rate(request))
        Ok(response) -> Ok(response)
        Error(_) -> Error(CarrierXApiRequestFailed)
  action()

fun perform-fetch-rate(request : carrier-x-rate-request)
  : <ask<carrier-x-api-environment>,async,exn> carrier-x-rate-response
  val environment : carrier-x-api-environment = ask()
  val response = post(
    environment.base-url ++ "/shipping-rates",
    encode-rate-request(request)
  )
  decode-rate-response(response)

fun encode-rate-request(request : carrier-x-rate-request) : http-body
  [ ("destination", request.destination)
  , ("weightGrams", request.weight-grams.show)
  ]

fun decode-rate-response(_response : http-response) : carrier-x-rate-response
  Carrier-x-rate-response(1000, "CarrierX")
