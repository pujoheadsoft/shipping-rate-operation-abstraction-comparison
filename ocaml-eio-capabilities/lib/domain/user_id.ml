type t = User_id of string

let make value = User_id value
let value (User_id value) = value
