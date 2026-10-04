module data/non-empty

import std/async

pub struct non-empty<a>(
  head : a,
  tail : list<a>
)

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

pub fun non-empty/interleaved(
  Non-empty(head, tail) : non-empty<() -> <async|e> a>
) : <async|e> non-empty<a>
  val (head-result, tail-results) = interleaved(head, fn () tail.interleaved)
  Non-empty(head-result, tail-results)
