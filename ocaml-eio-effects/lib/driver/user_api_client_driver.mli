type environment = { base_url : string }

val run : http:User_http_client.t -> environment -> (unit -> 'a) -> 'a
