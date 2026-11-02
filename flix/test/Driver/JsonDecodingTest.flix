use Driver.UserApiClientDriver.decodeUserResponse
use Gateway.UserApiClient.UserResponse

@Test
def decodeUserResponseTest(): Unit \ Assert =
    let result = decodeUserResponse("{\"postalCode\":\"111-1111\"}");
    Assert.assertTrue(match result {
        case Ok(UserResponse.UserResponse({ postalCode = "111-1111" })) => true
        case _ => false
    })
