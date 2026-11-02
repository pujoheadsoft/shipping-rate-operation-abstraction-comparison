type error = Transport_failed | Invalid_response
type t = { get : string -> (Http_types.response, error) result }
