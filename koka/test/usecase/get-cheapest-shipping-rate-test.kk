module test/usecase/get-cheapest-shipping-rate-test

import test/assert
import domain/postal-code
import domain/weight
import domain/shipment
import domain/shipping-rate
import domain/shipping-rates
import domain/user-id
import data/non-empty
import usecase/get-cheapest-shipping-rate
import usecase/postal-code-port
import usecase/shipping-rate-port

pub fun test-get-cheapest-rate() : ()
  val user-id = User-id("userId")
  val weight = Weight(500)
  val postal-code = Postal-code("111-1111")
  val shipment = Shipment(postal-code, weight)
  val rates = Shipping-rates(Non-empty(
      Shipping-rate("配送業者X", 200), [
      Shipping-rate("配送業者Y", 100),
      Shipping-rate("配送業者Z", 300)
    ]))

  val expected = Shipping-rate("配送業者Y", 100)
  val actual =
    with fun fetch-postal-code-by-user-id(id)
      assert-equals("指定したユーザーIDが渡される", user-id, id)
      Ok(postal-code)
    with fun fetch-shipping-rates(s)
      assert-equals("Portに指定した荷物が渡される", shipment, s)
      Ok(rates)
    get-cheapest-shipping-rate(user-id, weight)

  assert-equals("一番安い送料を取得できる", Ok(expected), actual)

pub fun test-get-cheapest-rate-fails-when-postal-code-fetch-fails() : ()
  val actual =
    with fun fetch-postal-code-by-user-id(_id)
      Error(FetchPostalCodeFailed)
    with fun fetch-shipping-rates(_shipment)
      assert("郵便番号取得失敗時は送料取得Portを呼ばない", False)
      Error(FetchShippingRatesFailed)
    get-cheapest-shipping-rate(User-id("userId"), Weight(500))

  assert-equals(
    "郵便番号の取得に失敗したらユースケースのエラーが返る",
    Error(GetCheapestShippingRateFailed),
    actual
  )

pub fun test-get-cheapest-rate-fails-when-shipping-destination-is-not-found() : ()
  val actual =
    with fun fetch-postal-code-by-user-id(_id)
      Error(PostalCodeNotFound)
    with fun fetch-shipping-rates(_shipment)
      assert("配送先が存在しない場合は送料取得Portを呼ばない", False)
      Error(FetchShippingRatesFailed)
    get-cheapest-shipping-rate(User-id("unknown"), Weight(500))

  assert-equals(
    "郵便番号が存在しなければ配送先未登録エラーを返す",
    Error(ShippingDestinationNotFound),
    actual
  )

pub fun test-get-cheapest-rate-fails-when-shipping-rates-fetch-fails() : ()
  val actual =
    with fun fetch-postal-code-by-user-id(_id)
      Ok(Postal-code("111-1111"))
    with fun fetch-shipping-rates(_shipment)
      Error(FetchShippingRatesFailed)
    get-cheapest-shipping-rate(User-id("userId"), Weight(500))

  assert-equals(
    "送料の取得に失敗したらユースケースのエラーが返る",
    Error(GetCheapestShippingRateFailed),
    actual
  )
