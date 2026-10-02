module test/usecase/get-shipping-rates-test

import test/assert
import domain/shipment
import domain/shipping-rate
import domain/shipping-rates
import usecase/get-shipping-rates
import usecase/get-shipping-rates-error
import port/shipping-rate-port
import port/shipping-rate-error

pub fun test-get-shipping-rates() : ()
  val shipment = Shipment("111-1111", 10)
  val expected = Shipping-rates(Non-empty(Shipping-rate("配送業者X", 100), []))

  val actual =
    with fun fetch-shipping-rates(s) Ok(expected)
    get-shipping-rates(shipment) 

  assert-equals("荷物に対しての送料をすべて取得できる", Ok(expected), actual)

pub fun test-fail-get-shipping-rates() : ()
  val shipment = Shipment("111-1111", 10)

  val actual =
    with fun fetch-shipping-rates(s) Error(FetchShippingRatesFailed)
    get-shipping-rates(shipment)

  assert-equals(
    "送料取得エラーが起きた場合ユースケースのエラーが返る",
    Error(GetShippingRatesFailed),
    actual
  )
