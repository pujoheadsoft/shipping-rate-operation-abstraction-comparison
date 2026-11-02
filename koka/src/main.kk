module main

import std/async
import std/os/env
import effect/fail
import domain/user-id
import domain/weight
import domain/shipping-rate
import usecase/shipping-rate-port
import usecase/get-cheapest-shipping-rate
import gateway/shipping-rates-gateway
import gateway/postal-code-gateway
import driver/carrier-x-api-client-driver
import driver/carrier-y-api-client-driver
import driver/carrier-z-api-client-driver
import driver/user-api-client-driver

fun main() : <console,async,exn,ndet> ()
  val user-id = User-id("user-123")
  val weight = Weight(1000)
  val user-api-base-url = get-env("USER_API_BASE_URL", "http://localhost:8081")
  val carrier-x-api-base-url = get-env("CARRIER_X_API_BASE_URL", "http://localhost:8082")
  val carrier-y-api-base-url = get-env("CARRIER_Y_API_BASE_URL", "http://localhost:8083")
  val carrier-z-api-base-url = get-env("CARRIER_Z_API_BASE_URL", "http://localhost:8084")

  val rate-result : result<shipping-rate,get-cheapest-shipping-rate-error> =
    with with-carrier-x-api-client(Carrier-x-api-environment(carrier-x-api-base-url))
    with with-carrier-y-api-client(Carrier-y-api-environment(carrier-y-api-base-url))
    with with-carrier-z-api-client(Carrier-z-api-environment(carrier-z-api-base-url))
    with with-user-api-client(User-api-environment(user-api-base-url))
    with run-shipping-rate-port
    with run-postal-code-port
    get-cheapest-shipping-rate(user-id, weight)

  match rate-result
    Ok(rate) ->
      println("一番安い送料の取得に成功しました。")
      print-shipping-rate(rate)
    Error(ShippingDestinationNotFound) ->
      println("配送先が見つかりませんでした。")
    Error(GetCheapestShippingRateFailed) ->
      println("一番安い送料の取得に失敗しました。")

fun print-shipping-rate(Shipping-rate(carrier, amount)) : console ()
  println("  " ++ carrier ++ ": " ++ amount.show ++ "円")

fun get-env(name : string, default-value : string) : <ndet> string
  match get-env-value(name)
    Just(value) -> value
    Nothing -> default-value
