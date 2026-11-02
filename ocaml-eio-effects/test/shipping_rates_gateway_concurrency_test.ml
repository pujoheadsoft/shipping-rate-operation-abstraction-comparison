open Shipping_rate_eio_effects
open Test_support

let overlap () =
  Eio_mock.Backend.run @@ fun () ->
  let started = ref 0 in
  let all_started, release = Eio.Promise.create () in
  let wait_for_all () =
    incr started;
    if !started = 3 then Eio.Promise.resolve release ();
    Eio.Promise.await all_started
  in
  let result =
    run_gateway
      ~x:(fun _ ->
        wait_for_all ();
        Ok x_response)
      ~y:(fun _ ->
        wait_for_all ();
        Ok y_response)
      ~z:(fun _ ->
        wait_for_all ();
        Ok z_response)
      (fun () ->
        Gateway.Fetch_error.run (fun () ->
            Gateway.Shipping_rates_gateway.fetch_shipping_rates shipment))
  in
  match result with
  | Ok rates ->
      Alcotest.(check int) "all effects started" 3 !started;
      check_rates "X/Y/Z rates" expected_rates rates
  | Error _ -> Alcotest.fail "expected success"

let cancellation () =
  Eio_mock.Backend.run @@ fun () ->
  let started = ref 0 in
  let stopped = ref 0 in
  let all_started, release = Eio.Promise.create () in
  let never, _never_resolver = Eio.Promise.create () in
  let wait_forever _ =
    Fun.protect
      ~finally:(fun () -> incr stopped)
      (fun () ->
        incr started;
        if !started = 3 then Eio.Promise.resolve release ();
        Eio.Promise.await never;
        failwith "unreachable promise resolved")
  in
  let result =
    Eio.Fiber.first
      (fun () ->
        ignore
          (run_gateway ~x:wait_forever ~y:wait_forever ~z:wait_forever
             (fun () ->
               Gateway.Fetch_error.run (fun () ->
                   Gateway.Shipping_rates_gateway.fetch_shipping_rates shipment)));
        `Unexpected_completion)
      (fun () ->
        Eio.Promise.await all_started;
        `Cancel)
  in
  Alcotest.(check bool) "cancel branch won" true (result = `Cancel);
  Alcotest.(check int) "all effect branches stopped" 3 !stopped

let cases =
  [
    Alcotest.test_case "unhandled Carrier effects overlap in child fibers"
      `Quick overlap;
    Alcotest.test_case "parent cancellation stops all child fibers" `Quick
      cancellation;
  ]
