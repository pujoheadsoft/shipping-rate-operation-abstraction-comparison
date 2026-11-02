type request = { postal_code : string; weight : int }
type response = { amount : int; service_code : string }
type error = Carrier_z_api_operation_failed
type t = { fetch_rate : request -> (response, error) result }
