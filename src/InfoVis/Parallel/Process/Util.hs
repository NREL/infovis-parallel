module InfoVis.Parallel.Process.Util (
  timestamp
, collectMessages
) where


import Control.Concurrent.MVar (MVar, isEmptyMVar, newEmptyMVar, putMVar, readMVar)
import Control.Distributed.Process (Process, expect, expectTimeout)
import Control.Distributed.Process.Serializable (Serializable)
import Data.Function (on)
import Data.Function.MapReduce (groupReduceFlatten)
import Data.List (groupBy, sortBy)
import Graphics.Rendering.OpenGL.GL.Tensor.Instances ()
import InfoVis.Parallel.Types.Message (SumTag(..))
import System.Clock as C
import System.IO.Unsafe (unsafePerformIO)



timestamp :: String -> IO ()
timestamp s =
  do
    t0' <- t0
    t <- C.toNanoSecs <$> C.getTime C.Monotonic
    putStrLn $ show (fromIntegral (t - t0') * 120 / 1e9 :: Double) ++ "\t" ++ s


t0Var :: MVar Integer
{-# NOINLINE t0Var #-}
t0Var = unsafePerformIO newEmptyMVar


t0 :: IO Integer
t0 =
  do
    e <- isEmptyMVar t0Var
    if e
      then do
                 t0' <- C.toNanoSecs <$> C.getTime C.Monotonic
                 putMVar t0Var t0'
                 return t0'
      else readMVar t0Var


collectMessages :: (Serializable a, SumTag a) => (a -> a -> Bool) -> Process [a]
collectMessages grouper =
  do
    let
      collectMessages' =
        do
          maybeMessage <- expectTimeout 1
          case maybeMessage of
            Nothing      -> return []
            Just message -> (message :) <$> collectMessages'
      collapser = fmap head . groupBy (grouper `on` snd)
    message <- expect
    messages <- collectMessages'
    return
      . map snd
      . sortBy (compare `on` fst)
      . groupReduceFlatten (sumTag . snd) collapser
      . zip [(0::Int),-1..]
      $ message : messages

