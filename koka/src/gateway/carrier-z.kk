module gateway/carrier-z

pub struct carrier-z-rate-request(
  postal-code : string,
  weight : int
)

pub struct carrier-z-rate-response(
  amount : int,
  service-code : string
)

pub fun carrier-z-rate-request/(==)(a : carrier-z-rate-request, b : carrier-z-rate-request) : bool
  a.postal-code == b.postal-code && a.weight == b.weight

pub fun carrier-z-rate-response/(==)(a : carrier-z-rate-response, b : carrier-z-rate-response) : bool
  a.amount == b.amount && a.service-code == b.service-code

pub fun carrier-z-rate-request/show(request : carrier-z-rate-request) : string
  "Carrier-z-rate-request(postal-code=\"" ++ request.postal-code
    ++ "\", weight=" ++ request.weight.show ++ ")"

pub fun carrier-z-rate-response/show(response : carrier-z-rate-response) : string
  "Carrier-z-rate-response(amount=" ++ response.amount.show
    ++ ", service-code=\"" ++ response.service-code ++ "\")"
