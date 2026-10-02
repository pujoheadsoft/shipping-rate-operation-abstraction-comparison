module test/gateway/shipping-rates-gateway-test

import std/async
import effect/ask
import effect/fail
import test/assert
import domain/shipping-rates
import domain/shipping-rate
import domain/shipment
import port/shipping-rate-error
import gateway/shipping-rates-gateway
import gateway/carrier-x
import gateway/carrier-y
import gateway/carrier-z

pub fun test-fetch-shipping-rates() : <async,exn> ()
  val shipment = Shipment("111-1111", 1000)
  val rateX = Shipping-rate("SericeCodeX", 1000)
  val rateY = Shipping-rate("CarrierY", 2000)
  val rateZ = Shipping-rate("ServiceCodeZ", 3000)
  val expected = Shipping-rates(Non-empty(rateX, [rateY, rateZ]))

  val deps = Dependencies(
    fetch-carrier-x-rate = fn (request : carrier-x-rate-request) {
      assert-equals("expected request x", Carrier-x-rate-request("111-1111", 1000), request)
      Carrier-x-rate-response(1000, "SericeCodeX")
    },
    fetch-carrier-y-rate = fn (request) {
      assert-equals("expected request y", Carrier-y-rate-request("111-1111", 1000), request)
      Carrier-y-rate-response(2000, "CarrierY")
    },
    fetch-carrier-z-rate = fn (request) {
      assert-equals("expected request z", Carrier-z-rate-request("111-1111", 1000), request)
      Carrier-z-rate-response(3000, "ServiceCodeZ")
    }
  )

  val actual =
    with fun ask()
      deps
    with final ctl fail(e)
      impossible("エラーは発生しない")
    fetch-shipping-rates(shipment)

  assert-equals("3社すべての送料が一致する", expected, actual)

pub fun test-fail-fetch-shipping-rates() : <async, exn> ()
  val shipment = Shipment("111-1111", 1000)
  val deps = Dependencies(
    fetch-carrier-x-rate = fn (request : carrier-x-rate-request) {
      assert-equals("expected request x", Carrier-x-rate-request("111-1111", 1000), request)
      Carrier-x-rate-response(1000, "SericeCodeX")
    },
    fetch-carrier-y-rate = fn (request) {
      assert-equals("expected request y", Carrier-y-rate-request("111-1111", 1000), request)
      throw("エラーが発生しました")
    },
    fetch-carrier-z-rate = fn (request) {
      assert-equals("expected request z", Carrier-z-rate-request("111-1111", 1000), request)
      Carrier-z-rate-response(3000, "ServiceCodeZ")
    }
  )


  with fun ask() deps
  with final ctl fail(e)
    assert-equals("送料取得エラーが発生する", FetchShippingRatesFailed, e)
  fetch-shipping-rates(shipment)

  assert("failが呼ばれるはず", False)
