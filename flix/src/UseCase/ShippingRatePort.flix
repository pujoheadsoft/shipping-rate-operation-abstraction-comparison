pub mod UseCase.ShippingRatePort {
    pub eff ShippingRatePort {
        def fetchShippingRates(
            shipment: Domain.Shipment.Shipment
        ): Result[FetchShippingRatesError, Domain.ShippingRates.ShippingRates]
    }

    pub enum FetchShippingRatesError with Eq, ToString {
        case FetchShippingRatesFailed
    }
}
