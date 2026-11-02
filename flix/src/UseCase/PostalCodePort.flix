pub mod UseCase.PostalCodePort {
    use Domain.UserId
    use Domain.PostalCode

    pub eff PostalCodePort {
        def fetchPostalCodeByUserId(id: UserId):
          Result[FetchPostalCodeError, PostalCode]
    }

    pub enum FetchPostalCodeError with Eq, ToString {
        case PostalCodeNotFound
        case FetchPostalCodeFailed
    }
}