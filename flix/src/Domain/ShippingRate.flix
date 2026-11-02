pub mod Domain.ShippingRate {
    pub enum ShippingRate({
        carrier = String,
        amount = Int32
    })

    instance Eq[ShippingRate] {
        pub def eq(x: ShippingRate, y: ShippingRate): Bool =
            let ShippingRate(xRate) = x;
            let ShippingRate(yRate) = y;
            xRate#carrier == yRate#carrier and xRate#amount == yRate#amount
    }

    instance ToString[ShippingRate] {
        pub def toString(rate: ShippingRate): String =
            let ShippingRate(value) = rate;
            "ShippingRate({carrier = ${value#carrier}, amount = ${value#amount}})"
    }
}
