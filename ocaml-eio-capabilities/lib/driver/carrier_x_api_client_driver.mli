type environment = { base_url : string }

val create : http:Http_client.t -> environment -> Gateway.Carrier_x_api_client.t
