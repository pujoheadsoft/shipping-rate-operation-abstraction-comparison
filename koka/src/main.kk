module main

import std/async
import effect/fail
import domain/shipment
import domain/shipping-rate
import domain/shipping-rates
import data/non-empty
import usecase/shipping-rate-port
import usecase/get-shipping-rates
import gateway/shipping-rates-gateway
import driver/carrier-x-http-client-driver
import driver/carrier-y-http-client-driver
import driver/carrier-z-http-client-driver

fun main() : <console,async,exn> ()
  val shipment = Shipment("111-1111", 1000)

  val rates-result : result<shipping-rates,get-shipping-rates-error> =
    with with-carrier-x-http-client(Carrier-x-http-environment("https://carrier-x.example.com"))
    with with-carrier-y-http-client(Carrier-y-http-environment("https://carrier-y.example.com"))
    with with-carrier-z-http-client(Carrier-z-http-environment("https://carrier-z.example.com"))
    with fun usecase/shipping-rate-port/fetch-shipping-rates(value)
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
