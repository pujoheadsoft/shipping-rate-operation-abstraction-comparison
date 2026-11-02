type t = Shipping_rates of Shipping_rate.t Data.Non_empty.t

let make head tail = Shipping_rates (Data.Non_empty.make head tail)
let to_list (Shipping_rates rates) = Data.Non_empty.to_list rates

let find_cheapest (Shipping_rates rates) =
  let choose (cheapest : Shipping_rate.t) (rate : Shipping_rate.t) =
    if rate.amount < cheapest.amount then rate else cheapest
  in
  match Data.Non_empty.to_list rates with
  | first :: rest -> List.fold_left choose first rest
  | [] -> assert false
