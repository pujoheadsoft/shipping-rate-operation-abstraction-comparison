module Driver.Error (DriverError(..)) where

import Prelude

data DriverError = DriverOperationFailed

derive instance Eq DriverError
