module gateway/carrier-x-http-client

import gateway/http-types

pub effect carrier-x-http-client
  fun post(request : http-request) : result<http-response,http-error>
