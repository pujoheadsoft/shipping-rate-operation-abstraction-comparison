package rates.gateway

import kyo.*
import kyo.kernel.*
import rates.domain.*
import rates.usecase.*

object PostalCodeGateway:
  def run[A, S](program: A < (PostalCodePort & S))(using Frame): A < (UserApiClient & Async & S) =
    ArrowEffect.handleLoop(Tag[PostalCodePort], program)([C] =>
      operation =>
        operation match
          case PostalCodePort.Op.Fetch(userId) =>
            fetch(userId).map(value => Loop.continue(value))
    )

  private def fetch(userId: UserId)(using Frame): FetchPostalCodeResult < (UserApiClient & Async) =
    UserApiClient.fetch(UserRequest(userId.value)).map {
      case Right(user) => Right(PostalCode(user.postalCode))
      case Left(UserApiError.UserApiUserNotFound) => Left(FetchPostalCodeError.PostalCodeNotFound)
      case Left(UserApiError.UserApiOperationFailed) => Left(FetchPostalCodeError.FetchPostalCodeFailed)
    }
