open Shipping_rate_eio_capabilities
module X_driver = Driver.Carrier_x_api_client_driver
module Y_driver = Driver.Carrier_y_api_client_driver
module Z_driver = Driver.Carrier_z_api_client_driver
module User_driver = Driver.User_api_client_driver

let get_env name default_value =
  Option.value (Sys.getenv_opt name) ~default:default_value

let program env =
  let dependencies : Gateway.Shipping_rates_gateway.dependencies =
    {
      carrier_x =
        X_driver.create
          ~http:(Driver.Piaf_http_client.create ~env)
          X_driver.
            {
              base_url =
                get_env "CARRIER_X_API_BASE_URL" "http://localhost:8082";
            };
      carrier_y =
        Y_driver.create
          ~http:(Driver.Piaf_http_client.create ~env)
          Y_driver.
            {
              base_url =
                get_env "CARRIER_Y_API_BASE_URL" "http://localhost:8083";
            };
      carrier_z =
        Z_driver.create
          ~http:(Driver.Piaf_http_client.create ~env)
          Z_driver.
            {
              base_url =
                get_env "CARRIER_Z_API_BASE_URL" "http://localhost:8084";
            };
    }
  in
  let port =
    Gateway.Shipping_rates_gateway.create_shipping_rate_port dependencies
  in
  let user_api =
    User_driver.create
      ~http:(Driver.Piaf_http_client.create_user ~env)
      User_driver.
        { base_url = get_env "USER_API_BASE_URL" "http://localhost:8081" }
  in
  let postal_code_port = Gateway.Postal_code_gateway.create user_api in
  Usecase.Get_cheapest_shipping_rate.get_cheapest_shipping_rate postal_code_port
    port (Domain.User_id.make "user-123") (Domain.Weight.make 1000)

let print_shipping_rate (rate : Domain.Shipping_rate.t) =
  print_endline "一番安い送料の取得に成功しました。";
  Printf.printf "  %s: %d円\n" rate.carrier rate.amount

let () =
  Eio_main.run @@ fun _env ->
  match program _env with
  | Ok rate -> print_shipping_rate rate
  | Error Usecase.Get_cheapest_shipping_rate.Shipping_destination_not_found ->
      prerr_endline "配送先が登録されていません。"
  | Error Usecase.Get_cheapest_shipping_rate.Get_cheapest_shipping_rate_failed ->
      prerr_endline "一番安い送料の取得に失敗しました。"
