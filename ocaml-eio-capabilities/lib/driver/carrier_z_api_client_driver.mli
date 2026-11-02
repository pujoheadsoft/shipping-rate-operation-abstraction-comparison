type environment = { base_url : string }

val create : http:Http_client.t -> environment -> Gateway.Carrier_z_api_client.t
