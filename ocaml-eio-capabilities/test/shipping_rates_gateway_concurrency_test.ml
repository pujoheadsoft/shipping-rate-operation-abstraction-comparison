open Shipping_rate_eio_capabilities
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
  let dependencies =
    dependencies
      ~x:(fun _ ->
        wait_for_all ();
        Ok x_response)
      ~y:(fun _ ->
        wait_for_all ();
        Ok y_response)
      ~z:(fun _ ->
        wait_for_all ();
        Ok z_response)
  in
  match
    Gateway.Shipping_rates_gateway.fetch_shipping_rates dependencies shipment
  with
  | Ok rates ->
      Alcotest.(check int) "all branches started" 3 !started;
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
  let dependencies =
    dependencies ~x:wait_forever ~y:wait_forever ~z:wait_forever
  in
  let result =
    Eio.Fiber.first
      (fun () ->
        ignore
          (Gateway.Shipping_rates_gateway.fetch_shipping_rates dependencies
             shipment);
        `Unexpected_completion)
      (fun () ->
        Eio.Promise.await all_started;
        `Cancel)
  in
  Alcotest.(check bool) "cancel branch won" true (result = `Cancel);
  Alcotest.(check int) "all branches stopped" 3 !stopped

let cases =
  [
    Alcotest.test_case "three capability calls overlap" `Quick overlap;
    Alcotest.test_case "parent cancellation stops all children" `Quick
      cancellation;
  ]
