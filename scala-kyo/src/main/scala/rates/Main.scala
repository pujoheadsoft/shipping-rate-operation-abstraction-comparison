package rates

import kyo.*
import rates.domain.*
import rates.driver.*
import rates.gateway.*
import rates.usecase.*

object Main extends KyoApp:
  private val carrierXEnvironment = CarrierXApiEnvironment("https://carrier-x.example.com")
  private val carrierYEnvironment = CarrierYApiEnvironment("https://carrier-y.example.com")
  private val carrierZEnvironment = CarrierZApiEnvironment("https://carrier-z.example.com")

  run {
    val shipment = Shipment("111-1111", 1000)
    GetShippingRates(shipment).handle(
      ShippingRatesGateway.run(_),
      CarrierXApiClientDriver.run(carrierXEnvironment)(_),
      CarrierYApiClientDriver.run(carrierYEnvironment)(_),
      CarrierZApiClientDriver.run(carrierZEnvironment)(_),
      Abort.run[GetShippingRatesError](_)
    )
  }
