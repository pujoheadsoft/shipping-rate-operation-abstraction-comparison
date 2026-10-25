pub mod Domain.ShippingRates {
    pub enum ShippingRates with Eq, ToString {
        case ShippingRates(
            Domain.ShippingRate.ShippingRate,
            List[Domain.ShippingRate.ShippingRate]
        )
    }
}
