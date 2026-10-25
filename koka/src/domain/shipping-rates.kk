module domain/shipping-rates

import domain/shipping-rate
import data/non-empty

pub struct shipping-rates(
  values : non-empty<shipping-rate>
)

pub fun shipping-rates/find-cheapest(Shipping-rates(Non-empty(x, xs))) : shipping-rate
  xs.foldl(x) fn(cheapest, rate)
    if rate.amount < cheapest.amount then
      rate
    else
      cheapest

pub fun shipping-rates/(==)(
  Shipping-rates(values1),
  Shipping-rates(values2)
) : bool
  values1 == values2

pub fun shipping-rates/show(Shipping-rates(values)) : string
  "Shipping-rates(" ++ values.show ++ ")"
