module domain/user-id

pub struct user-id(id : string)

pub fun user-id/(==)(User-id(id1), User-id(id2)) : bool
  id1 == id2

pub fun user-id/show(User-id(id)) : string
  "UserID: " ++ id