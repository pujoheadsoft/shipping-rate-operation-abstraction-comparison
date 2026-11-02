package rates.usecase

import kyo.*
import kyo.kernel.*
import rates.domain.*

enum FetchPostalCodeError:
  case PostalCodeNotFound
  case FetchPostalCodeFailed

type FetchPostalCodeResult = Either[FetchPostalCodeError, PostalCode]

sealed trait PostalCodePort extends ArrowEffect[PostalCodePort.Op, Id]

object PostalCodePort:
  enum Op[A]:
    case Fetch(userId: UserId) extends Op[FetchPostalCodeResult]

  private[rates] given Tag[PostalCodePort] = Tag.derive

  def fetch(userId: UserId)(using Frame): FetchPostalCodeResult < PostalCodePort =
    ArrowEffect.suspend(Tag[PostalCodePort], Op.Fetch(userId))
