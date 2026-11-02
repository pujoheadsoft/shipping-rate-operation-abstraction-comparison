type environment = { base_url : string }

val create :
  http:User_http_client.t -> environment -> Gateway.User_api_client.t
