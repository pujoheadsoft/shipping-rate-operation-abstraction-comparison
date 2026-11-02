package rates.driver

import kyo.*

enum DriverError:
  case DriverOperationFailed

final case class GetResponse(status: Int, body: String)

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

  def get(url: String)(using Frame): Either[DriverError, GetResponse] < Async = Abort
    .runPartialOrThrow[HttpException, kyo.HttpResponse["body" ~ String], Async](
      kyo.HttpClient.getTextResponse(url, failOnError = false)
    )
    .map {
      case Result.Success(response) =>
        Right(GetResponse(response.status.code, response.fields.body))
      case Result.Failure(_) =>
        Left(DriverError.DriverOperationFailed)
    }
