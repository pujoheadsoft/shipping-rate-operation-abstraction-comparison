module Test.UseCase.GetShippingRates (testGetShippingRates) where

import Prelude

import Effect (Effect)
import Test.Assert (assert')

testGetShippingRates :: Effect Unit
testGetShippingRates =
  assert' "returns shipping rates for the specified shipment" false
