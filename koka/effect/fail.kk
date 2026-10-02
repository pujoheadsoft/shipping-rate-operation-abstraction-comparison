module effect/fail

pub effect fail<e>
  final ctl fail(error : e) : a

pub fun fail-on-exn(error : b, action : () -> <exn,fail<b>|e> a) : <fail<b>|e> a
  try(
    fn (exn) fail(error),
    action
  )