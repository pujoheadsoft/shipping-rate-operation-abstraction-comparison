module driver/user-api-client-driver

import std/async
import effect/ask
import gateway/user-api-client
import driver/driver-error
import driver/http-types
import driver/http-client

pub struct user-api-environment(base-url : string)

pub fun with-user-api-client(
  environment : user-api-environment,
  action : () -> <user-api-client,async|e> a
) : <async|e> a
  with handler
    fun gateway/user-api-client/fetch-user(request)
      with fun ask() environment
      match to-driver-result(fn () perform-fetch-user(request))
        Ok(result) -> result
        Error(_) -> Error(UserApiOperationFailed)
  action()

fun perform-fetch-user(User-request(id) : user-request)
  : <ask<user-api-environment>,async,exn> result<user-response,user-api-error>
  val environment : user-api-environment = ask()
  val response = get(environment.base-url ++ "/users/" ++ id)
  decode-user-response(response)

fun decode-user-response(response : http-response) : result<user-response,user-api-error>
  if response.status == 404 then
    Error(UserApiUserNotFound)
  elif response.status != 200 then
    Error(UserApiOperationFailed)
  else
    Ok(User-response("111-1111"))
