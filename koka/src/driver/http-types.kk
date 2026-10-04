module driver/http-types

pub alias http-body = list<(string,string)>

pub struct http-response(
  status : int,
  body : http-body
)

pub type http-error
  HttpRequestFailed

pub fun http-response/(==)(a : http-response, b : http-response) : bool
  a.status == b.status && a.body == b.body

pub fun http-response/show(response : http-response) : string
  "Http-response(status=" ++ response.status.show ++ ", body=" ++ response.body.show ++ ")"
