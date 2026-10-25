module gateway/postal-code-gateway

import domain/postal-code
import domain/user-id
import usecase/postal-code-port
import gateway/user-api-client

pub fun run-postal-code-port(
  action : () -> <postal-code-port,user-api-client|e> a
) : <user-api-client|e> a
  with fun usecase/postal-code-port/fetch-postal-code-by-user-id(user-id)
    fetch-postal-code(user-id)
  action()

pub fun fetch-postal-code(User-id(id) : user-id)
  : user-api-client result<postal-code,fetch-postal-code-error>
  match gateway/user-api-client/fetch-user(User-request(id))
    Ok(User-response(code)) -> Ok(Postal-code(code))
    Error(UserApiUserNotFound) -> Error(PostalCodeNotFound)
    Error(UserApiOperationFailed) -> Error(FetchPostalCodeFailed)
