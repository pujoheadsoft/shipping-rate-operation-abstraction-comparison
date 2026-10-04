module gateway/carrier-x-api-client

pub struct carrier-x-rate-request(
  destination : string,
  weight-grams : int
)

pub struct carrier-x-rate-response(
  amount : int,
  service-code : string
)

pub type carrier-x-api-error
  CarrierXApiOperationFailed

pub effect carrier-x-api-client
  fun fetch-rate(request : carrier-x-rate-request)
    : result<carrier-x-rate-response,carrier-x-api-error>

pub fun carrier-x-rate-request/(==)(a : carrier-x-rate-request, b : carrier-x-rate-request) : bool
  a.destination == b.destination && a.weight-grams == b.weight-grams

pub fun carrier-x-rate-request/show(request : carrier-x-rate-request) : string
  "Carrier-x-rate-request(\"" ++ request.destination ++ "\", " ++ request.weight-grams.show ++ ")"
