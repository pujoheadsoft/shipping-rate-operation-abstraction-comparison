package rates.gateway

import kyo.*
import kyo.kernel.*

final case class UserRequest(userId: String)
final case class UserResponse(postalCode: String)

enum UserApiError:
  case UserApiUserNotFound
  case UserApiOperationFailed

sealed trait UserApiClient extends ContextEffect[UserApiClient.Client]

object UserApiClient:
  trait Client:
    def fetch(request: UserRequest)(using Frame): Either[UserApiError, UserResponse] < Async

  private[rates] given Tag[UserApiClient] = Tag.derive

  def fetch(request: UserRequest)(using Frame): Either[UserApiError, UserResponse] < (UserApiClient & Async) =
    ContextEffect.suspendWith(Tag[UserApiClient])(_.fetch(request))
