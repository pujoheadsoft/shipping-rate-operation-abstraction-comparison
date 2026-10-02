module test/assert

pub fun assert-equals(
  message : string,
  expected : a,
  actual : a,
  ?element/(==) : (a, a) -> e bool,
  ?element/show : a -> e string,
  ?kk-file-line : string
) : e ()
  if !element/(==)(expected, actual) then
    assert(
      message
        ++ "\n  expected: " ++ element/show(expected)
        ++ "\n  actual:   " ++ element/show(actual),
      False,
      ?kk-file-line=?kk-file-line
    )
