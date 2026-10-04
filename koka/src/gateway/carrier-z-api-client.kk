module gateway/carrier-z-api-client

pub struct carrier-z-rate-request(
  postal-code : string,
  weight : int
)

pub struct carrier-z-rate-response(
  amount : int,
  service-code : string
)

pub type carrier-z-api-error
  CarrierZApiOperationFailed

pub effect carrier-z-api-client
  fun fetch-rate(request : carrier-z-rate-request)
    : result<carrier-z-rate-response,carrier-z-api-error>

pub fun carrier-z-rate-request/(==)(a : carrier-z-rate-request, b : carrier-z-rate-request) : bool
  a.postal-code == b.postal-code && a.weight == b.weight

pub fun carrier-z-rate-request/show(request : carrier-z-rate-request) : string
  "Carrier-z-rate-request(\"" ++ request.postal-code ++ "\", " ++ request.weight.show ++ ")"
