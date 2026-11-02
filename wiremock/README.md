# Local API dependencies

The runnable samples use WireMock instead of external User and Carrier APIs.

```sh
make dependencies-up
make run-flix # or any other run-<language> target
make dependencies-down
```

Each API is isolated in its own service and host port:

| Environment variable | Default URL | Endpoint |
| --- | --- | --- |
| `USER_API_BASE_URL` | `http://localhost:8081` | `GET /users/user-123` |
| `CARRIER_X_API_BASE_URL` | `http://localhost:8082` | `POST /shipping-rates` |
| `CARRIER_Y_API_BASE_URL` | `http://localhost:8083` | `POST /rates/quote` |
| `CARRIER_Z_API_BASE_URL` | `http://localhost:8084` | `POST /shipping/quote` |

Every application composition root uses the environment variable when it is
set and otherwise uses the listed local URL. The WireMock mappings verify the
carrier-specific request JSON before returning their carrier-specific response
JSON.
