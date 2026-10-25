module Run.Parallel
  ( ParallelRun
  , liftRun
  , liftParallel
  , parallelSequence
  , runParallel
  ) where

import Prelude

import Control.Applicative.Free (FreeAp, foldFreeAp, liftFreeAp)
import Control.Monad.Free (Free, foldFree, liftF)
import Control.Parallel (parallel, sequential)
import Data.Traversable (class Traversable, traverse)
import Effect.Aff (Aff)
import Run (Run)

newtype ParallelRun r a = ParallelRun (Free (FreeAp (Run r)) a)

derive newtype instance Functor (ParallelRun r)
derive newtype instance Apply (ParallelRun r)
derive newtype instance Applicative (ParallelRun r)
derive newtype instance Bind (ParallelRun r)
derive newtype instance Monad (ParallelRun r)

liftRun :: forall r a. Run r a -> ParallelRun r a
liftRun = liftFreeAp >>> liftParallel

liftParallel :: forall r. FreeAp (Run r) ~> ParallelRun r
liftParallel = ParallelRun <<< liftF

parallelSequence
  :: forall t r a
   . Traversable t
  => t (Run r a)
  -> FreeAp (Run r) (t a)
parallelSequence = traverse liftFreeAp

runParallel :: forall r. (Run r ~> Aff) -> ParallelRun r ~> Aff
runParallel interpret (ParallelRun program) = foldFree runBatch program
  where
  runBatch :: FreeAp (Run r) ~> Aff
  runBatch = foldFreeAp (parallel <<< interpret) >>> sequential
