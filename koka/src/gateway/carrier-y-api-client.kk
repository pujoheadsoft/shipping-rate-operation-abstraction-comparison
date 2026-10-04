module gateway/carrier-y-api-client

pub struct carrier-y-rate-request(
  postal-code : string,
  weight : int
)

pub struct carrier-y-rate-response(
  price : int,
  service-name : string
)

pub type carrier-y-api-error
  CarrierYApiRequestFailed

pub effect carrier-y-api-client
  fun fetch-rate(request : carrier-y-rate-request)
    : result<carrier-y-rate-response,carrier-y-api-error>

pub fun carrier-y-rate-request/(==)(a : carrier-y-rate-request, b : carrier-y-rate-request) : bool
  a.postal-code == b.postal-code && a.weight == b.weight

pub fun carrier-y-rate-request/show(request : carrier-y-rate-request) : string
  "Carrier-y-rate-request(\"" ++ request.postal-code ++ "\", " ++ request.weight.show ++ ")"
