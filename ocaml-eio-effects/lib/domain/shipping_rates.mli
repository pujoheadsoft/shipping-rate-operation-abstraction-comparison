type t

val make : Shipping_rate.t -> Shipping_rate.t list -> t
val to_list : t -> Shipping_rate.t list
val find_cheapest : t -> Shipping_rate.t
