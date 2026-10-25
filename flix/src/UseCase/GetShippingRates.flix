pub mod UseCase.GetShippingRates {
    use Domain.Shipment.Shipment
    use Domain.ShippingRates.ShippingRates
    use UseCase.ShippingRatePort.ShippingRatePort

    pub enum GetShippingRatesError with Eq, ToString {
        case GetShippingRatesFailed
    }

    pub def getShippingRates(
        shipment: Shipment
    ): Result[GetShippingRatesError, ShippingRates] \ ShippingRatePort =
        match ShippingRatePort.fetchShippingRates(shipment) {
            case Ok(rates) => Ok(rates)
            case Err(_)    => Err(GetShippingRatesError.GetShippingRatesFailed)
        }
}
