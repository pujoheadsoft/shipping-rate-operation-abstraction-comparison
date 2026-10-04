module gateway/http-types

pub alias http-body = list<(string,string)>

pub struct http-request(
  path : string,
  body : http-body
)

pub struct http-response(
  status : int,
  body : http-body
)

pub type http-error
  HttpRequestFailed

pub fun http-request/(==)(a : http-request, b : http-request) : bool
  a.path == b.path && a.body == b.body

pub fun http-response/(==)(a : http-response, b : http-response) : bool
  a.status == b.status && a.body == b.body

pub fun http-request/show(request : http-request) : string
  "Http-request(path=\"" ++ request.path ++ "\", body=" ++ request.body.show ++ ")"

pub fun http-response/show(response : http-response) : string
  "Http-response(status=" ++ response.status.show ++ ", body=" ++ response.body.show ++ ")"
