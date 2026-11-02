package rates.domain

final case class ShippingRates(head: ShippingRate, tail: List[ShippingRate]):
  def findCheapest: ShippingRate = tail.foldLeft(head) { (cheapest, rate) =>
    if rate.amount < cheapest.amount then rate else cheapest
  }
