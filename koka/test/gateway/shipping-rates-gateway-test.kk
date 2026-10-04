module test/gateway/shipping-rates-gateway-test

import std/async
import effect/fail
import test/assert
import domain/shipping-rates
import domain/shipping-rate
import domain/shipment
import data/non-empty
import usecase/shipping-rate-port
import gateway/shipping-rates-gateway
import gateway/http-types
import gateway/carrier-x-http-client
import gateway/carrier-y-http-client
import gateway/carrier-z-http-client

pub fun test-fetch-shipping-rates() : <async,exn> ()
  val shipment = Shipment("111-1111", 1000)
  val rateX = Shipping-rate("ServiceCodeX", 1000)
  val rateY = Shipping-rate("CarrierY", 2000)
  val rateZ = Shipping-rate("ServiceCodeZ", 3000)
  val expected = Shipping-rates(Non-empty(rateX, [rateY, rateZ]))

  val actual =
    with fun gateway/carrier-x-http-client/post(request)
      assert-equals("expected request x", Http-request("/shipping-rates", [("destination", "111-1111"), ("weightGrams", "1000")]), request)
      yield()
      Ok(Http-response(200, [("amount", "1000"), ("serviceCode", "ServiceCodeX")]))
    with fun gateway/carrier-y-http-client/post(request)
      assert-equals("expected request y", Http-request("/rates/quote", [("postalCode", "111-1111"), ("weight", "1000")]), request)
      yield()
      Ok(Http-response(200, [("price", "2000"), ("serviceName", "CarrierY")]))
    with fun gateway/carrier-z-http-client/post(request)
      assert-equals("expected request z", Http-request("/shipping/quote", [("postalCode", "111-1111"), ("weight", "1000")]), request)
      yield()
      Ok(Http-response(200, [("amount", "3000"), ("serviceCode", "ServiceCodeZ")]))
    with final ctl fail(e)
      impossible("エラーは発生しない")
    gateway/shipping-rates-gateway/fetch-shipping-rates(shipment)

  assert-equals("3社すべての送料が一致する", expected, actual)

pub fun test-fail-fetch-shipping-rates() : <async, exn> ()
  val shipment = Shipment("111-1111", 1000)
  with fun gateway/carrier-x-http-client/post(request)
    assert-equals("expected request x", Http-request("/shipping-rates", [("destination", "111-1111"), ("weightGrams", "1000")]), request)
    Ok(Http-response(200, [("amount", "1000"), ("serviceCode", "ServiceCodeX")]))
  with fun gateway/carrier-y-http-client/post(request)
    assert-equals("expected request y", Http-request("/rates/quote", [("postalCode", "111-1111"), ("weight", "1000")]), request)
    Error(HttpRequestFailed)
  with fun gateway/carrier-z-http-client/post(request)
    assert-equals("expected request z", Http-request("/shipping/quote", [("postalCode", "111-1111"), ("weight", "1000")]), request)
    Ok(Http-response(200, [("amount", "3000"), ("serviceCode", "ServiceCodeZ")]))
  with final ctl fail(e)
    assert-equals("送料取得エラーが発生する", FetchShippingRatesFailed, e)
  gateway/shipping-rates-gateway/fetch-shipping-rates(shipment)

  assert("failが呼ばれるはず", False)
