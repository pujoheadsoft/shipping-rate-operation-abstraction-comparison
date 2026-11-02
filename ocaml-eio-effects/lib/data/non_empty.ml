type 'a t = { head : 'a; tail : 'a list }

let make head tail = { head; tail }
let to_list { head; tail } = head :: tail
