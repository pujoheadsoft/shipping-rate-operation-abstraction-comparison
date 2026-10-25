module domain/postal-code

pub struct postal-code(code : string)

pub fun postal-code/(==)(Postal-code(v1), Postal-code(v2)) : bool
  v1 == v2

pub fun postal-code/show(Postal-code(v)) : string
  "PostalCode: " ++ v