module gateway/carrier-y-http-client

import gateway/http-types

pub effect carrier-y-http-client
  fun post(request : http-request) : result<http-response,http-error>
