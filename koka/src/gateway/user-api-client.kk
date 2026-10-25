module gateway/user-api-client

pub struct user-request(
  id : string
)

pub struct user-response(
  postal-code : string
)

pub type user-api-error
  UserApiUserNotFound
  UserApiOperationFailed

pub effect user-api-client
  fun fetch-user(request : user-request)
    : result<user-response,user-api-error>

pub fun user-request/(==)(User-request(id1), User-request(id2)) : bool
  id1 == id2

pub fun user-request/show(User-request(id)) : string
  "User-request(\"" ++ id ++ "\")"
