type request = { destination : string; weight_grams : int }
type response = { amount : int; service_code : string }
type error = Carrier_x_api_operation_failed
type t = { fetch_rate : request -> (response, error) result }
