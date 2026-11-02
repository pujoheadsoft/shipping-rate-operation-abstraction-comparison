type t = { destination_postal_code : string; weight : int }

let make ~destination_postal_code ~weight = { destination_postal_code; weight }
