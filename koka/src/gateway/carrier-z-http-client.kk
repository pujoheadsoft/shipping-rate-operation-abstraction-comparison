module gateway/carrier-z-http-client

import gateway/http-types

pub effect carrier-z-http-client
  fun post(request : http-request) : result<http-response,http-error>
