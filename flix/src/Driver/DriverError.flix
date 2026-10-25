pub mod Driver.DriverError {
    pub enum DriverError with Eq, ToString {
        case DriverOperationFailed
    }
}
