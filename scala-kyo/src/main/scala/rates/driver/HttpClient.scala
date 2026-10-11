package rates.driver

import kyo.*

enum DriverError:
  case DriverOperationFailed

object HttpClient:
  def post(url: String, body: String)(using Frame): Either[DriverError, String] < Async = Abort
    .runPartialOrThrow[HttpException, String, Async](
      kyo.HttpClient.postText(url, body, headers = Seq("Content-Type" -> "application/json"))
    )
    .map {
      case Result.Success(response) =>
        Right(response)
      case Result.Failure(_) =>
        Left(DriverError.DriverOperationFailed)
    }
