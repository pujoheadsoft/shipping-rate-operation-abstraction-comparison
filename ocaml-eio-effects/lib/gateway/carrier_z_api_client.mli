type request = { postal_code : string; weight : int }
type response = { amount : int; service_code : string }
type error = Carrier_z_api_operation_failed

val fetch_rate : request -> (response, error) result
val run : fetch:(request -> (response, error) result) -> (unit -> 'a) -> 'a
