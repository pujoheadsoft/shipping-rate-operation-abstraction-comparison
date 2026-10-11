def main(): Unit \ {Chan, NonDet, IO} =
    let shipment = Shipment.Shipment("111-1111", 1000);
    let xEnvironment = CarrierXApiEnvironment.CarrierXApiEnvironment(
        "https://carrier-x.example.com"
    );
    let yEnvironment = CarrierYApiEnvironment.CarrierYApiEnvironment(
        "https://carrier-y.example.com"
    );
    let zEnvironment = CarrierZApiEnvironment.CarrierZApiEnvironment(
        "https://carrier-z.example.com"
    );
    println(runShippingRatePort(
        () -> getShippingRates(shipment),
        carrierXApiClientHandler(xEnvironment),
        carrierYApiClientHandler(yEnvironment),
        carrierZApiClientHandler(zEnvironment)
    ))
