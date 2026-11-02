pub mod Driver.UserApiClientDriver {
    use Driver.HttpClient.decodeJson
    use Gateway.UserApiClient.{UserApiClient, UserApiError, UserRequest, UserResponse}
    use Net.Http
    use Net.HttpResponse
    use Net.HttpResponse.HttpResponse
    use Util.Json
    use Util.Json.FromJson
    use Util.Json.JsonError

    pub enum UserApiEnvironment({ baseUrl = String })

    enum UserResponseJson({ postalCode = String })

    instance FromJson[UserResponseJson] {
        pub def fromJson(json: Json): Result[JsonError, UserResponseJson] =
            FromJson.decodeAtKey("postalCode", json)
                |> Result.map(postalCode -> UserResponseJson.UserResponseJson({ postalCode = postalCode }))
    }

    pub def runUserApiClient(
        environment: UserApiEnvironment,
        action: Unit -> a \ ef
    ): a \ (ef - UserApiClient) + IO = run { action() } with handler UserApiClient {
        def fetchUser(request, resume) = resume(performFetchUser(environment, request))
    }

    def performFetchUser(
        environment: UserApiEnvironment,
        request: UserRequest
    ): Result[UserApiError, UserResponse] \ IO =
        let UserApiEnvironment.UserApiEnvironment({ baseUrl = baseUrl }) = environment;
        let UserRequest.UserRequest({ userId = userId }) = request;
        Http.runWithIO(() -> Http.get("${baseUrl}/users/${userId}"))
            |> Result.mapErr(_ -> UserApiError.UserApiOperationFailed)
            |> Result.flatMap(decodeUserHttpResponse)

    def decodeUserHttpResponse(response: HttpResponse): Result[UserApiError, UserResponse] =
        if (HttpResponse.isSuccess(response))
            decodeUserResponse(HttpResponse.body(response))
        else if (HttpResponse.status(response) == 404)
            Err(UserApiError.UserApiUserNotFound)
        else
            Err(UserApiError.UserApiOperationFailed)

    pub def decodeUserResponse(body: String): Result[UserApiError, UserResponse] =
        decodeJson(body)
            |> Result.map(toUserResponse)
            |> Result.mapErr(_ -> UserApiError.UserApiOperationFailed)

    def toUserResponse(response: UserResponseJson): UserResponse =
        let UserResponseJson.UserResponseJson({ postalCode = postalCode }) = response;
        UserResponse.UserResponse({ postalCode = postalCode })
}
