module test/gateway/shipping-rates-gateway-test

import std/async
import effect/fail
import test/assert
import domain/postal-code
import domain/weight
import domain/shipping-rates
import domain/shipping-rate
import domain/shipment
import data/non-empty
import usecase/shipping-rate-port
import gateway/shipping-rates-gateway
import gateway/carrier-x-api-client
import gateway/carrier-y-api-client
import gateway/carrier-z-api-client

pub fun test-fetch-shipping-rates() : <async,exn> ()
  val shipment = Shipment(Postal-code("111-1111"), Weight(1000))
  val rateX = Shipping-rate("CarrierX", 1000)
  val rateY = Shipping-rate("CarrierY", 2000)
  val rateZ = Shipping-rate("CarrierZ", 3000)
  val expected = Shipping-rates(Non-empty(rateX, [rateY, rateZ]))

  val actual =
    with fun gateway/carrier-x-api-client/fetch-rate(request)
      assert-equals("expected request x", Carrier-x-rate-request("111-1111", 1000), request)
      yield()
      Ok(Carrier-x-rate-response(1000, "EXPRESS"))
    with fun gateway/carrier-y-api-client/fetch-rate(request)
      assert-equals("expected request y", Carrier-y-rate-request("111-1111", 1000), request)
      yield()
      Ok(Carrier-y-rate-response(2000, "Standard Delivery"))
    with fun gateway/carrier-z-api-client/fetch-rate(request)
      assert-equals("expected request z", Carrier-z-rate-request("111-1111", 1000), request)
      yield()
      Ok(Carrier-z-rate-response(3000, "ECONOMY"))
    with final ctl fail(e)
      impossible("エラーは発生しない")
    gateway/shipping-rates-gateway/fetch-shipping-rates(shipment)

  assert-equals("3社すべての送料が一致する", expected, actual)

pub fun test-fail-fetch-shipping-rates() : <async, exn> ()
  val shipment = Shipment(Postal-code("111-1111"), Weight(1000))
  with fun gateway/carrier-x-api-client/fetch-rate(request)
    assert-equals("expected request x", Carrier-x-rate-request("111-1111", 1000), request)
    Ok(Carrier-x-rate-response(1000, "EXPRESS"))
  with fun gateway/carrier-y-api-client/fetch-rate(request)
    assert-equals("expected request y", Carrier-y-rate-request("111-1111", 1000), request)
    Error(CarrierYApiOperationFailed)
  with fun gateway/carrier-z-api-client/fetch-rate(request)
    assert-equals("expected request z", Carrier-z-rate-request("111-1111", 1000), request)
    Ok(Carrier-z-rate-response(3000, "ECONOMY"))
  with final ctl fail(e)
    assert-equals("Carrier APIの失敗をFetchShippingRatesFailedに変換する", FetchShippingRatesFailed, e)
  gateway/shipping-rates-gateway/fetch-shipping-rates(shipment)

  assert("failが呼ばれるはず", False)
