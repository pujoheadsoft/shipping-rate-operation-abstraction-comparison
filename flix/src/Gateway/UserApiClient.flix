pub mod Gateway.UserApiClient {
    use Gateway.UserApiClient.UserRequest
    use Gateway.UserApiClient.UserResponse

    pub eff UserApiClient {
        def fetchUser(request: UserRequest): Result[UserApiError, UserResponse]
    }

    pub enum UserRequest({ userId = String })

    pub enum UserResponse({ postalCode = String })

    pub enum UserApiError with Eq, ToString {
        case UserApiUserNotFound
        case UserApiOperationFailed
    }
}
