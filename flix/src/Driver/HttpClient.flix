pub mod Driver.HttpClient {
    use Driver.DriverError.DriverError
    use Net.Http
    use Net.HttpResponse
    use Util.Json
    use Util.Json.FromJson

    pub def postJson(url: String, body: String): Result[DriverError, a] \ IO with FromJson[a] =
        Http.runWithIO(() -> Http.postWith(url, body))
            |> Result.mapErr(_ -> DriverError.DriverOperationFailed)
            |> Result.flatMap(response ->
                if (HttpResponse.isSuccess(response))
                    decodeJson(HttpResponse.body(response))
                else
                    Err(DriverError.DriverOperationFailed)
            )

    pub def decodeJson(body: String): Result[DriverError, a] with FromJson[a] =
        Json.decode(body)
            |> Result.mapErr(_ -> DriverError.DriverOperationFailed)
}
