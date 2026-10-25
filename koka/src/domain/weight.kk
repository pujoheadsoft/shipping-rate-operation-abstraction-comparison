module domain/weight

pub struct weight(value : int)

pub fun weight/(==)(Weight(v1), Weight(v2)) : bool
  v1 == v2

pub fun weight/show(Weight(v)) : string
  "Weight: " ++ v.show