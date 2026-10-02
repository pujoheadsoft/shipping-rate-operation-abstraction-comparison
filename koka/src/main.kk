module main

import std/async
import effect/ask
import effect/fail
import domain/shipment
import domain/shipping-rate
import domain/shipping-rates
import port/shipping-rate-port
import usecase/get-shipping-rates
import usecase/get-shipping-rates-error
import gateway/shipping-rates-gateway
import gateway/carrier-x
import gateway/carrier-y
import gateway/carrier-z

fun main() : <console,async,exn> ()
  val dependencies = Dependencies(
    fetch-carrier-x-rate = fn (request : carrier-x-rate-request) {
      Carrier-x-rate-response(1000, "CarrierX")
    },
    fetch-carrier-y-rate = fn (request : carrier-y-rate-request) {
      Carrier-y-rate-response(2000, "CarrierY")
    },
    fetch-carrier-z-rate = fn (request : carrier-z-rate-request) {
      Carrier-z-rate-response(3000, "CarrierZ")
    }
  )

  val shipment = Shipment("111-1111", 1000)

  val rates-result : result<shipping-rates,get-shipping-rates-error> =
    with fun ask() dependencies
    with fun port/shipping-rate-port/fetch-shipping-rates(value)
      with final ctl fail(error)
        Error(error)
      Ok(gateway/shipping-rates-gateway/fetch-shipping-rates(value))
    get-shipping-rates(shipment)

  match rates-result
    Ok(rates) ->
      print-shipping-rates(rates)
    Error(GetShippingRatesFailed) ->
      println("送料の取得に失敗しました。配送業者から送料を取得できませんでした。")

fun print-shipping-rates(Shipping-rates(Non-empty(head, tail))) : console ()
  println("送料の取得に成功しました。")
  Cons(head, tail).foreach(print-shipping-rate)

fun print-shipping-rate(Shipping-rate(carrier, amount)) : console ()
  println("  " ++ carrier ++ ": " ++ amount.show ++ "円")
