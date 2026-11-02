pub mod Domain.ShippingRates {
    use Reducible.foldLeft
    use Domain.ShippingRate.ShippingRate

    pub enum ShippingRates with Eq, ToString {
        case ShippingRates(ShippingRate, List[ShippingRate])
    }

    pub def findCheapest(rates: ShippingRates): ShippingRate =
        let ShippingRates(first, rest) = rates;
        List.foldLeft(chooseCheaper, first, rest)

    def chooseCheaper(x: ShippingRate, y: ShippingRate): ShippingRate =
        let ShippingRate({ carrier = _, amount = xPrice }) = x;
        let ShippingRate({ carrier = _, amount = yPrice }) = y;
        if (xPrice <= yPrice) x else y
}
