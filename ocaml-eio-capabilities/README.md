# OCaml + Eio capabilities

The UseCase Port and the three carrier clients are ordinary OCaml records of
functions. The Gateway receives those capabilities explicitly and uses nested
`Eio.Fiber.pair` calls to fetch Carrier X, Y, and Z concurrently.

The application starts with a user ID and weight, obtains the destination
postal code through the User API, fetches all three carrier rates, and selects
the cheapest rate in the UseCase. A missing destination short-circuits before
the shipping-rate capability is called.

This variant does not make application operations into effects. Eio may use
OCaml effects internally to implement fibers, but the application dependency
abstraction remains record capabilities.

The driver layer keeps HTTP behind injected carrier and User HTTP interfaces.
`Piaf_http_client.create ~env` and `create_user ~env` provide the production Eio HTTP/HTTPS adapters;
it leaves Eio cancellation exceptions untouched while mapping Piaf transport
and response-body errors at the HTTP boundary. The executable uses these
adapters and defaults to local services on ports 8081 through 8084. Carrier
Driver contract tests cover the URL, request JSON,
status handling, and response JSON for all three carriers; real-network
integration remains outside the test suite.

The verified toolchain is OCaml 5.3.0, Dune 3.20.1, Eio 1.3, Yojson 2.2.2,
Piaf 0.2.0, Alcotest 1.9.0, and ocamlformat 0.29.0. Dependencies are declared
in `shipping-rate-eio-capabilities.opam`; install them in the selected opam
switch before using the targets below.

```sh
opam exec -- dune build
opam exec -- dune runtest
opam exec -- dune exec bin/main.exe
```
