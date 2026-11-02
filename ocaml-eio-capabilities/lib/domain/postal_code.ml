type t = Postal_code of string

let make value = Postal_code value
let value (Postal_code value) = value
