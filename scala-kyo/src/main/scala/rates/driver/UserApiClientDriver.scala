package rates.driver

import kyo.*
import kyo.kernel.*
import rates.gateway.*
import scala.util.control.NonFatal

final case class UserApiEnvironment(baseUrl: String)

object UserApiClientDriver:
  def run[A, S](environment: UserApiEnvironment)(program: A < (UserApiClient & S))(using
      Frame
  ): A < (Async & S) = ContextEffect.handleInheritable(Tag[UserApiClient], create(environment))(program)

  private def create(environment: UserApiEnvironment): UserApiClient.Client =
    new UserApiClient.Client:
      def fetch(request: UserRequest)(using Frame): Either[UserApiError, UserResponse] < Async =
        rates.driver.HttpClient.get(s"${environment.baseUrl}/users/${request.userId}").map {
          case Left(_) => Left(UserApiError.UserApiOperationFailed)
          case Right(GetResponse(404, _)) => Left(UserApiError.UserApiUserNotFound)
          case Right(GetResponse(status, _)) if status < 200 || status >= 300 => Left(UserApiError.UserApiOperationFailed)
          case Right(GetResponse(_, body)) => decode(body)
        }

  private def decode(body: String): Either[UserApiError, UserResponse] =
    try Right(UserResponse(ujson.read(body)("postalCode").str))
    catch case NonFatal(_) => Left(UserApiError.UserApiOperationFailed)
