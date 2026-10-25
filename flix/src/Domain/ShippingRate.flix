pub mod Domain.ShippingRate {
    pub enum ShippingRate with Eq, ToString {
        case ShippingRate(String, Int32)
    }
}
