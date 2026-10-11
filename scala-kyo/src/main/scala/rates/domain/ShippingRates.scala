package rates.domain

final case class ShippingRates(head: ShippingRate, tail: List[ShippingRate])
