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
import driver/carrier-x-api-client-driver
import driver/carrier-y-api-client-driver
import driver/carrier-z-api-client-driver

fun main() : <console,async,exn> ()
  val shipment = Shipment("111-1111", 1000)

  val rates-result : result<shipping-rates,get-shipping-rates-error> =
    with with-carrier-x-api-client(Carrier-x-api-environment("https://carrier-x.example.com"))
    with with-carrier-y-api-client(Carrier-y-api-environment("https://carrier-y.example.com"))
    with with-carrier-z-api-client(Carrier-z-api-environment("https://carrier-z.example.com"))
    with run-shipping-rate-port
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
