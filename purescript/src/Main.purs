module Main (main) where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Hello (hello)

main :: Effect Unit
main = log hello
