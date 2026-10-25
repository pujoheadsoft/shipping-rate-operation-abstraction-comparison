module test/domain/shipping-rates-test

import test/assert
import data/non-empty
import domain/shipping-rate
import domain/shipping-rates

pub fun test-find-cheapest() : ()
  val rates = Shipping-rates(Non-empty(
      Shipping-rate("配送業者X", 200), [
      Shipping-rate("配送業者Y", 100),
      Shipping-rate("配送業者Z", 300)
    ]))

  val actual = rates.find-cheapest()
  assert-equals("一番安い送料を返す", Shipping-rate("配送業者Y", 100), actual)

pub fun test-find-cheapest-returns-first-on-tie() : ()
  val rates = Shipping-rates(Non-empty(
      Shipping-rate("配送業者X", 200), [
      Shipping-rate("配送業者Y", 100),
      Shipping-rate("配送業者Z", 100)
    ]))

  val actual = rates.find-cheapest()
  assert-equals("最安が複数あるなら最初に見つかったものを返す", Shipping-rate("配送業者Y", 100), actual)