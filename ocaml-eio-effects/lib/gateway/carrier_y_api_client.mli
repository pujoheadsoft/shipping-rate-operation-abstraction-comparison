type request = { postal_code : string; weight : int }
type response = { price : int; service_name : string }
type error = Carrier_y_api_operation_failed

val fetch_rate : request -> (response, error) result
val run : fetch:(request -> (response, error) result) -> (unit -> 'a) -> 'a
