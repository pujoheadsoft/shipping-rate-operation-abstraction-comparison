module gateway/shipping-rates-gateway

import std/async
import effect/fail
import domain/shipment
import domain/shipping-rate
import domain/shipping-rates
import domain/postal-code
import domain/weight
import data/non-empty
import usecase/shipping-rate-port
import gateway/carrier-x-api-client
import gateway/carrier-y-api-client
import gateway/carrier-z-api-client

pub fun run-shipping-rate-port(
  action : () -> <shipping-rate-port,carrier-x-api-client,carrier-y-api-client,
                   carrier-z-api-client,async|e> a
) : <carrier-x-api-client,carrier-y-api-client,carrier-z-api-client,async|e> a
  with fun usecase/shipping-rate-port/fetch-shipping-rates(value)
    with final ctl fail(error)
      Error(error)
    Ok(fetch-shipping-rates(value))
  action()

pub fun fetch-shipping-rates(shipment : shipment)
  : <carrier-x-api-client,carrier-y-api-client,carrier-z-api-client,async,
     fail<fetch-shipping-rates-error>> shipping-rates

  val rates = Non-empty(
    fn () fetch-carrier-x-rate(shipment),
    [ fn () fetch-carrier-y-rate(shipment)
    , fn () fetch-carrier-z-rate(shipment)
    ]
  ).interleaved

  Shipping-rates(rates)

fun fetch-carrier-x-rate(shipment : shipment)
  : <carrier-x-api-client,fail<fetch-shipping-rates-error>> shipping-rate
  gateway/carrier-x-api-client/fetch-rate(shipment.to-carrier-x-rate-request)
    .from-api-result
    .to-carrier-x-shipping-rate

fun fetch-carrier-y-rate(shipment : shipment)
  : <carrier-y-api-client,fail<fetch-shipping-rates-error>> shipping-rate
  gateway/carrier-y-api-client/fetch-rate(shipment.to-carrier-y-rate-request)
    .from-api-result
    .to-carrier-y-shipping-rate

fun fetch-carrier-z-rate(shipment : shipment)
  : <carrier-z-api-client,fail<fetch-shipping-rates-error>> shipping-rate
  gateway/carrier-z-api-client/fetch-rate(shipment.to-carrier-z-rate-request)
    .from-api-result
    .to-carrier-z-shipping-rate

fun from-api-result(value : result<a,b>)
  : fail<fetch-shipping-rates-error> a
  match value
    Ok(response) -> response
    Error(_) -> fail(FetchShippingRatesFailed)

fun shipment/to-carrier-x-rate-request((Shipment (Postal-code(code), Weight(weight)))) : carrier-x-rate-request
  Carrier-x-rate-request(code, weight)

fun shipment/to-carrier-y-rate-request((Shipment (Postal-code(code), Weight(weight)))) : carrier-y-rate-request
  Carrier-y-rate-request(code, weight)

fun shipment/to-carrier-z-rate-request((Shipment (Postal-code(code), Weight(weight)))) : carrier-z-rate-request
  Carrier-z-rate-request(code, weight)

fun carrier-x-rate-response/to-carrier-x-shipping-rate(
  response : carrier-x-rate-response
) : shipping-rate
  Shipping-rate("CarrierX", response.amount)

fun carrier-y-rate-response/to-carrier-y-shipping-rate(
  response : carrier-y-rate-response
) : shipping-rate
  Shipping-rate("CarrierY", response.price)

fun carrier-z-rate-response/to-carrier-z-shipping-rate(
  response : carrier-z-rate-response
) : shipping-rate
  Shipping-rate("CarrierZ", response.amount)
