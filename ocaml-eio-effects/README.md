# OCaml application effects interpreted by Eio

The UseCase Port, the three carrier clients, the Gateway error, and the
three-way parallel operation are application-defined OCaml effects. The
composition root installs their handlers and interprets `Parallel.All3` with
nested `Eio.Fiber.pair` calls.

The application starts with a user ID and weight, obtains the destination
postal code through the User API, fetches all three carrier rates, and selects
the cheapest rate in the UseCase. A missing destination short-circuits before
the shipping-rate effect is performed.

An OCaml effect handler is not automatically inherited as an application
handler by a child fiber. The Eio bridge therefore receives a polymorphic
`runner` and explicitly reinstalls the carrier handlers around every child.
This custom bridge is the experimental contrast in this directory; it should
not be read as the standard way to structure an OCaml/Eio application.

This is distinct from Eio using OCaml effects internally to implement its own
runtime. Here, shipping-rate operations themselves are defined with
`Effect.perform`.

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
in `shipping-rate-eio-effects.opam`; install them in the selected opam switch
before using the targets below.

```sh
opam exec -- dune build
opam exec -- dune runtest
opam exec -- dune exec bin/main.exe
```
