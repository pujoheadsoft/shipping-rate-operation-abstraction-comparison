module driver/driver-error

import std/async

pub type driver-error
  DriverOperationFailed

pub fun to-driver-result(action : () -> <async,exn|e> a)
  : <async|e> result<a,driver-error>
  try(
    fn (_) Error(DriverOperationFailed),
    fn () Ok(action())
  )

