type request = { url : string; body : Http_types.body }
type error = Transport_failed | Invalid_response
type t = { post : request -> (Http_types.response, error) result }
