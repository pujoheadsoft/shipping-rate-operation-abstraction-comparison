type environment = { base_url : string }

val run : http:Http_client.t -> environment -> (unit -> 'a) -> 'a
