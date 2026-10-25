module domain/shipment

import domain/postal-code
import domain/weight

pub struct shipment(
  destination-postal-code : postal-code,
  weight : weight
)

pub fun shipment/(==)(
  Shipment(postal-code1, weight1),
  Shipment(postal-code2, weight2)
) : bool
  postal-code1 == postal-code2 && weight1 == weight2

pub fun shipment/show(Shipment(postal-code, weight)) : string
  "Shipment(\"" ++ postal-code.show ++ "\", " ++ weight.show ++ ")"
