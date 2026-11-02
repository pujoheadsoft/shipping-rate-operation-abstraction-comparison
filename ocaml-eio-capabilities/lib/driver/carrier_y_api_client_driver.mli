type environment = { base_url : string }

val create : http:Http_client.t -> environment -> Gateway.Carrier_y_api_client.t
