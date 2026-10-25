pub mod Domain.Shipment {
    use Domain.PostalCode
    use Domain.Weight

    pub enum Shipment with Eq, ToString {
        case Shipment(PostalCode, Weight)
    }
}
