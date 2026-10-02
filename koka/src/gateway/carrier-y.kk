module gateway/carrier-y

pub struct carrier-y-rate-request(
  postal-code : string,
  weight : int
)

pub struct carrier-y-rate-response(
  price : int,
  service-name : string
)

pub fun carrier-y-rate-request/(==)(a : carrier-y-rate-request, b : carrier-y-rate-request) : bool
  a.postal-code == b.postal-code && a.weight == b.weight

pub fun carrier-y-rate-response/(==)(a : carrier-y-rate-response, b : carrier-y-rate-response) : bool
  a.price == b.price && a.service-name == b.service-name

pub fun carrier-y-rate-request/show(request : carrier-y-rate-request) : string
  "Carrier-y-rate-request(postal-code=\"" ++ request.postal-code
    ++ "\", weight=" ++ request.weight.show ++ ")"

pub fun carrier-y-rate-response/show(response : carrier-y-rate-response) : string
  "Carrier-y-rate-response(price=" ++ response.price.show
    ++ ", service-name=\"" ++ response.service-name ++ "\")"
