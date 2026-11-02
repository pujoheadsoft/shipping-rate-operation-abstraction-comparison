exception Invalid_response

let require_success (response : Http_types.response) =
  if response.status < 200 || response.status >= 300 then raise Invalid_response;
  Yojson.Safe.from_string response.body

let member name json = Yojson.Safe.Util.member name json
let string name json = Yojson.Safe.Util.to_string (member name json)
let int name json = Yojson.Safe.Util.to_int (member name json)
