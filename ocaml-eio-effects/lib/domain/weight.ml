type t = Weight of int

let make value = Weight value
let value (Weight value) = value
