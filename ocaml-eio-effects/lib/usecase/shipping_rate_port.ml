type fetch_error = Fetch_shipping_rates_failed

type _ Effect.t +=
  | Fetch_shipping_rates :
      Domain.Shipment.t
      -> (Domain.Shipping_rates.t, fetch_error) result Effect.t

let fetch_shipping_rates shipment =
  Effect.perform (Fetch_shipping_rates shipment)

let run : type a.
    fetch:(Domain.Shipment.t -> (Domain.Shipping_rates.t, fetch_error) result) ->
    (unit -> a) ->
    a =
 fun ~fetch action ->
  Effect.Deep.try_with action ()
    {
      effc =
        (fun (type b) (eff : b Effect.t) ->
          match eff with
          | Fetch_shipping_rates shipment ->
              Some
                (fun (continuation : (b, _) Effect.Deep.continuation) ->
                  Effect.Deep.continue continuation (fetch shipment))
          | _ -> None);
    }
