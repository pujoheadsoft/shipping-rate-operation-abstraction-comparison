use Net.Http
use Net.HttpResponse

def postJson(url: String, body: String): Result[DriverError, String] \ IO =
    Http.runWithIO(() -> match Http.postWith(url, body) {
        case Ok(response) if HttpResponse.isSuccess(response) => Ok(HttpResponse.body(response))
        case _ => Err(DriverError.DriverOperationFailed)
    })
