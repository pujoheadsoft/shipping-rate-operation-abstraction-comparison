exception Invalid_response

val require_success : Http_types.response -> Yojson.Safe.t
val string : string -> Yojson.Safe.t -> string
val int : string -> Yojson.Safe.t -> int
