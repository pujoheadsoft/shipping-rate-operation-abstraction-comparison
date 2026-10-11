enum GetShippingRatesError with Eq, ToString { case GetShippingRatesFailed }

def getShippingRates(
    shipment: Shipment
): Result[GetShippingRatesError, ShippingRates] \ ShippingRatePort =
    match ShippingRatePort.fetchShippingRates(shipment) {
        case Ok(rates) => Ok(rates)
        case Err(_)    => Err(GetShippingRatesError.GetShippingRatesFailed)
    }
