module gateway/shipping-rates-gateway

import std/async
import effect/fail
import domain/shipment
import domain/shipping-rate
import domain/shipping-rates
import data/non-empty
import usecase/shipping-rate-port
import gateway/http-types
import gateway/carrier-x-http-client
import gateway/carrier-y-http-client
import gateway/carrier-z-http-client

pub fun fetch-shipping-rates(shipment : shipment)
  : <carrier-x-http-client,carrier-y-http-client,carrier-z-http-client,async,
     fail<fetch-shipping-rates-error>> shipping-rates

  val rates = Non-empty(
    fn () fetch-carrier-x-rate(shipment),
    [ fn () fetch-carrier-y-rate(shipment)
    , fn () fetch-carrier-z-rate(shipment)
    ]
  ).interleaved

  Shipping-rates(rates)

fun fetch-carrier-x-rate(shipment : shipment)
  : <carrier-x-http-client,fail<fetch-shipping-rates-error>> shipping-rate
  gateway/carrier-x-http-client/post(shipment.to-carrier-x-http-request)
    .from-http-result
    .to-carrier-x-shipping-rate

fun fetch-carrier-y-rate(shipment : shipment)
  : <carrier-y-http-client,fail<fetch-shipping-rates-error>> shipping-rate
  gateway/carrier-y-http-client/post(shipment.to-carrier-y-http-request)
    .from-http-result
    .to-carrier-y-shipping-rate

fun fetch-carrier-z-rate(shipment : shipment)
  : <carrier-z-http-client,fail<fetch-shipping-rates-error>> shipping-rate
  gateway/carrier-z-http-client/post(shipment.to-carrier-z-http-request)
    .from-http-result
    .to-carrier-z-shipping-rate

fun from-http-result(value : result<http-response,http-error>)
  : fail<fetch-shipping-rates-error> http-response
  match value
    Ok(response) -> response
    Error(_) -> fail(FetchShippingRatesFailed)

fun shipment/to-carrier-x-http-request(s : shipment) : http-request
  Http-request("/shipping-rates", [
    ("destination", s.destination-postal-code),
    ("weightGrams", s.weight.show)
  ])

fun shipment/to-carrier-y-http-request(s : shipment) : http-request
  Http-request("/rates/quote", [
    ("postalCode", s.destination-postal-code),
    ("weight", s.weight.show)
  ])

fun shipment/to-carrier-z-http-request(s : shipment) : http-request
  Http-request("/shipping/quote", [
    ("postalCode", s.destination-postal-code),
    ("weight", s.weight.show)
  ])

fun http-response/to-carrier-x-shipping-rate(response : http-response)
  : fail<fetch-shipping-rates-error> shipping-rate
  Shipping-rate(
    response.body.required-field("serviceCode"),
    response.body.required-int-field("amount")
  )

fun http-response/to-carrier-y-shipping-rate(response : http-response)
  : fail<fetch-shipping-rates-error> shipping-rate
  Shipping-rate(
    response.body.required-field("serviceName"),
    response.body.required-int-field("price")
  )

fun http-response/to-carrier-z-shipping-rate(response : http-response)
  : fail<fetch-shipping-rates-error> shipping-rate
  Shipping-rate(
    response.body.required-field("serviceCode"),
    response.body.required-int-field("amount")
  )

fun http-body/required-field(body : http-body, name : string)
  : fail<fetch-shipping-rates-error> string
  match body.lookup(fn (field-name) field-name == name)
    Just(value) -> value
    Nothing -> fail(FetchShippingRatesFailed)

fun http-body/required-int-field(body : http-body, name : string)
  : fail<fetch-shipping-rates-error> int
  match body.required-field(name).parse-int
    Just(value) -> value
    Nothing -> fail(FetchShippingRatesFailed)
