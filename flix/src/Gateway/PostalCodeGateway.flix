pub mod Gateway.PostalCodeGateway {
    use Domain.PostalCode.PostalCode
    use Domain.UserId.UserId
    use Gateway.UserApiClient.{UserApiClient, UserApiError, UserRequest, UserResponse}
    use UseCase.PostalCodePort.{FetchPostalCodeError, PostalCodePort}

    pub def runPostalCodePort(
        action: Unit -> a \ ef
    ): a \ (ef - PostalCodePort) + UserApiClient = run {
        action()
    } with handler PostalCodePort {
        def fetchPostalCodeByUserId(userId, resume) =
            resume(fetchPostalCode(userId))
    }

    def fetchPostalCode(userId: UserId):
        Result[FetchPostalCodeError, PostalCode] \ UserApiClient =
        let UserId(userIdValue) = userId;
        let request = UserRequest.UserRequest({ userId = userIdValue });
        match UserApiClient.fetchUser(request) {
            case Ok(UserResponse.UserResponse({ postalCode = postalCodeValue })) =>
                Ok(PostalCode(postalCodeValue))
            case Err(UserApiError.UserApiUserNotFound) =>
                Err(FetchPostalCodeError.PostalCodeNotFound)
            case Err(UserApiError.UserApiOperationFailed) =>
                Err(FetchPostalCodeError.FetchPostalCodeFailed)
        }
}
