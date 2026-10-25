pub mod UseCase.ShippingRatePort {
    pub eff ShippingRatePort {
        def fetchShippingRates(
            shipment: Domain.Shipment.Shipment
        ): Result[FetchShippingRatesError, Domain.ShippingRates.ShippingRates]
    }

    pub enum FetchShippingRatesError with Eq, ToString {
        case FetchShippingRatesFailed
    }

    pub def handleWith(
        action: Unit -> a \ ShippingRatePort,
        port: Domain.Shipment.Shipment ->
            Result[FetchShippingRatesError, Domain.ShippingRates.ShippingRates] \ ef
    ): a \ ef =
        run { action() } with handler ShippingRatePort {
            def fetchShippingRates(shipment, resume) = resume(port(shipment))
        }
}
