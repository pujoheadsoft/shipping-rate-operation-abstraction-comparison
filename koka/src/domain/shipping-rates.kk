module domain/shipping-rates

import domain/shipping-rate

pub struct non-empty<a>(
  head : a,
  tail : list<a>
)

/**
 * 比較関数
 * ? は暗黙引数でKokaが自動で補ってくれる
 * ?element/(==) ~ は暗黙引数として a 型の比較関数を受け取るということ
 */
pub fun non-empty/(==)(
  Non-empty(head1, tail1) : non-empty<a>,
  Non-empty(head2, tail2) : non-empty<a>,
  ?element/(==) : (a, a) -> e bool
) : e bool
  element/(==)(head1, head2) && list/(==)(tail1, tail2, element/(==))

pub fun non-empty/show(
  Non-empty(head, tail) : non-empty<a>,
  ?element/show : a -> e string
) : e string
  "Non-empty(" ++ element/show(head) ++ ", " ++ list/show(tail, element/show) ++ ")"

pub struct shipping-rates(
  values : non-empty<shipping-rate>
)

pub fun shipping-rate/(==)(
  Shipping-rates(values1),
  Shipping-rates(values2)
) : bool
  values1 == values2

pub fun shipping-rates/show(Shipping-rates(values)) : string
  "Shipping-rates(" ++ values.show ++ ")"
