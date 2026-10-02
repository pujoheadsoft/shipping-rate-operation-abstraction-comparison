module domain/shipping-rate

pub struct shipping-rate(
  carrier : string,
  amount : int
)

pub fun shipping-rate/(==)(
  Shipping-rate(carrier1, amount1),
  Shipping-rate(carrier2, amount2)
) : bool
  carrier1 == carrier2 && amount1 == amount2

pub fun shipping-rate/show(Shipping-rate(carrier, amount)) : string
  "Shipping-rate(\"" ++ carrier ++ "\", " ++ amount.show ++ ")"
