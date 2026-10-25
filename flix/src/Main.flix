use Domain.Shipment.Shipment
use Domain.PostalCode
use Domain.Weight
use Driver.CarrierXApiClientDriver.{CarrierXApiEnvironment, carrierXApiClientHandler}
use Driver.CarrierYApiClientDriver.{CarrierYApiEnvironment, carrierYApiClientHandler}
use Driver.CarrierZApiClientDriver.{CarrierZApiEnvironment, carrierZApiClientHandler}
use Gateway.ShippingRatesGateway.runShippingRatePort
use UseCase.GetShippingRates.getShippingRates

def main(): Unit \ {Chan, NonDet, IO} =
    let shipment = Shipment(PostalCode("111-1111"), Weight(1000));
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
