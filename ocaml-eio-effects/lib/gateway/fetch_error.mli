type t = Fetch_shipping_rates_failed

val fail : t -> 'a
val run : (unit -> 'a) -> ('a, t) result
