module Test.Main (main) where

import Prelude

import Effect (Effect)
import Hello (hello)
import Test.Assert (assertEqual)
import Test.UseCase.GetShippingRates (testGetShippingRates)

main :: Effect Unit
main = do
  assertEqual
    { actual: hello
    , expected: "Hello, world!"
    }
  testGetShippingRates
