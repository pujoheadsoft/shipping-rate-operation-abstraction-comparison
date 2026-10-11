enum FetchShippingRatesError with Eq, ToString {
    case FetchShippingRatesFailed
}

eff ShippingRatePort {
    def fetchShippingRates(shipment: Shipment): Result[FetchShippingRatesError, ShippingRates]
}

def handleShippingRatePortWith(
    action: Unit -> a \ ShippingRatePort,
    port: Shipment -> Result[FetchShippingRatesError, ShippingRates] \ ef
): a \ ef =
    run { action() } with handler ShippingRatePort {
        def fetchShippingRates(shipment, resume) = resume(port(shipment))
    }
