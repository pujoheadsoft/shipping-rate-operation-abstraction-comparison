package rates.usecase

import kyo.*
import kyo.kernel.*
import rates.domain.*

enum FetchShippingRatesError:
  case FetchShippingRatesFailed

type FetchShippingRatesResult = Either[FetchShippingRatesError, ShippingRates]

sealed trait ShippingRatePort extends ArrowEffect[ShippingRatePort.Op, Id]

object ShippingRatePort:
  enum Op[A]:
    case Fetch(shipment: Shipment) extends Op[FetchShippingRatesResult]

  private[rates] given Tag[ShippingRatePort] = Tag.derive

  def fetch(shipment: Shipment)(using Frame): FetchShippingRatesResult < ShippingRatePort = ArrowEffect.suspend(
    Tag[ShippingRatePort],
    Op.Fetch(shipment)
  )
