pub mod Domain.Shipment {
    use Domain.PostalCode
    use Domain.Weight

    pub enum Shipment({
        destinationPostalCode = PostalCode,
        weight = Weight
    })

    instance Eq[Shipment] {
        pub def eq(x: Shipment, y: Shipment): Bool =
            let Shipment(r1) = x;
            let Shipment(r2) = y;
            r1#destinationPostalCode == r2#destinationPostalCode and
                r1#weight == r2#weight
    }

    instance ToString[Shipment] {
        pub def toString(x: Shipment): String =
            let Shipment(r) = x;
            "Shipment({destinationPostalCode = ${r#destinationPostalCode}, weight = ${r#weight}})"
    }
}
