module UseCase.PostalCodePort where

import Prelude
import Data.Either (Either)
import Domain.PostalCode (PostalCode)
import Domain.UserId (UserId)
import Run (Run, lift)
import Type.Proxy (Proxy(..))

data FetchPostalCodeError
  = PostalCodeNotFound
  | FetchPostalCodeFailed

derive instance Eq FetchPostalCodeError
instance Show FetchPostalCodeError where
  show PostalCodeNotFound = "PostalCodeNotFound"
  show FetchPostalCodeFailed = "FetchPostalCodeFailed"

data PostalCodePortF a = FetchPostalCodeByUserId
  UserId
  (Either FetchPostalCodeError PostalCode -> a)

derive instance Functor PostalCodePortF
type POSTAL_CODE_PORT = PostalCodePortF

fetchPostalCodeByUserId
  :: forall r
   . UserId
  -> Run
       (postalCodePort :: POSTAL_CODE_PORT | r)
       (Either FetchPostalCodeError PostalCode)
fetchPostalCodeByUserId userId =
  lift (Proxy :: Proxy "postalCodePort")
    $ FetchPostalCodeByUserId userId identity
