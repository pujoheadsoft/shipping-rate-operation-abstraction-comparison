module gateway/carrier-x

pub struct carrier-x-rate-request(
  destination : string,
  weight-grams : int
)

pub struct carrier-x-rate-response(
  amount : int,
  service-code : string
)

pub fun carrier-x-rate-request/(==)(a : carrier-x-rate-request, b : carrier-x-rate-request) : bool
  a.destination == b.destination && a.weight-grams == b.weight-grams

pub fun carrier-x-rate-response/(==)(a : carrier-x-rate-response, b : carrier-x-rate-response) : bool
  a.amount == b.amount && a.service-code == b.service-code

pub fun carrier-x-rate-request/show(request : carrier-x-rate-request) : string
  "Carrier-x-rate-request(destination=\"" ++ request.destination
    ++ "\", weight-grams=" ++ request.weight-grams.show ++ ")"

pub fun carrier-x-rate-response/show(response : carrier-x-rate-response) : string
  "Carrier-x-rate-response(amount=" ++ response.amount.show
    ++ ", service-code=\"" ++ response.service-code ++ "\")"
