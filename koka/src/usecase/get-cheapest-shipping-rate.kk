module usecase/get-cheapest-shipping-rate

import domain/shipment
import domain/shipping-rate
import domain/shipping-rates
import domain/user-id
import domain/weight
import usecase/postal-code-port
import usecase/shipping-rate-port

pub fun get-cheapest-shipping-rate-error/show(error : get-cheapest-shipping-rate-error) : string
  match error
    ShippingDestinationNotFound -> "ShippingDestinationNotFound"
    GetCheapestShippingRateFailed -> "GetCheapestShippingRateFailed"

pub fun get-cheapest-shipping-rate(user-id : user-id, weight : weight)
  : <postal-code-port,shipping-rate-port> result<shipping-rate,get-cheapest-shipping-rate-error>
  match fetch-postal-code-by-user-id(user-id)
    Ok(postal-code) ->
      match fetch-shipping-rates(Shipment(postal-code, weight))
        Ok(rates) -> Ok(rates.find-cheapest())
        Error(_) -> Error(GetCheapestShippingRateFailed)
    Error(PostalCodeNotFound) -> Error(ShippingDestinationNotFound)
    Error(FetchPostalCodeFailed) -> Error(GetCheapestShippingRateFailed)

pub type get-cheapest-shipping-rate-error
  ShippingDestinationNotFound
  GetCheapestShippingRateFailed

pub fun get-cheapest-shipping-rate-error/(==)(
  a : get-cheapest-shipping-rate-error,
  b : get-cheapest-shipping-rate-error
) : bool
  match (a, b)
    (ShippingDestinationNotFound, ShippingDestinationNotFound) -> True
    (GetCheapestShippingRateFailed, GetCheapestShippingRateFailed) -> True
    _ -> False
