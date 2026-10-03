module domain/shipment

pub struct shipment(
  destination-postal-code : string,
  weight : int
)

pub fun shipment/(==)(
  Shipment(postal-code1, weight1),
  Shipment(postal-code2, weight2)
) : bool
  postal-code1 == postal-code2 && weight1 == weight2

pub fun shipment/show(Shipment(postal-code, weight)) : string
  "Shipment(\"" ++ postal-code ++ "\", " ++ weight.show ++ ")"
