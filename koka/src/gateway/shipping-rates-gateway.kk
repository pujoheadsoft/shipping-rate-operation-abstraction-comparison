module gateway/shipping-rates-gateway

import std/async
import effect/ask
import effect/fail
import domain/shipment
import domain/shipping-rate
import domain/shipping-rates
import port/shipping-rate-error
import gateway/carrier-x
import gateway/carrier-y
import gateway/carrier-z

pub struct dependencies
  fetch-carrier-x-rate : carrier-x-rate-request -> <async,exn> carrier-x-rate-response
  fetch-carrier-y-rate : carrier-y-rate-request -> <async,exn> carrier-y-rate-response
  fetch-carrier-z-rate : carrier-z-rate-request -> <async,exn> carrier-z-rate-response

pub fun fetch-shipping-rates(shipment : shipment)
  : <ask<dependencies>,async,fail<fetch-shipping-rates-error>> shipping-rates
  with fail-on-exn(FetchShippingRatesFailed)

  val deps = ask()

  val [x-rate, y-rate, z-rate] = interleaved([
    fn () deps.fetch-carrier-x-rate.(shipment.to-carrier-x-rate-request).to-shipping-rate,
    fn () deps.fetch-carrier-y-rate.(shipment.to-carrier-y-rate-request).to-shipping-rate,
    fn () deps.fetch-carrier-z-rate.(shipment.to-carrier-z-rate-request).to-shipping-rate
  ])

  Shipping-rates(Non-empty(x-rate, [y-rate, z-rate]))

fun shipment/to-carrier-x-rate-request(s : shipment) : carrier-x-rate-request
  Carrier-x-rate-request(s.destination-postal-code, s.weight)

fun shipment/to-carrier-y-rate-request(s : shipment) : carrier-y-rate-request
  Carrier-y-rate-request(s.destination-postal-code, s.weight)

fun shipment/to-carrier-z-rate-request(s : shipment) : carrier-z-rate-request
  Carrier-z-rate-request(s.destination-postal-code, s.weight)

fun carrier-x-rate-response/to-shipping-rate(r : carrier-x-rate-response) : shipping-rate
  Shipping-rate(r.service-code, r.amount)

fun carrier-y-rate-response/to-shipping-rate(r : carrier-y-rate-response) : shipping-rate
  Shipping-rate(r.service-name, r.price)

fun carrier-z-rate-response/to-shipping-rate(r : carrier-z-rate-response) : shipping-rate
  Shipping-rate(r.service-code, r.amount)
