module Control.Concurrent.MVar.Util (
  modifyMVar'
) where


import Control.Concurrent.MVar (MVar, modifyMVar_)


modifyMVar' :: MVar a
            -> (a -> a)
            -> IO ()
modifyMVar' = (. (return .)) . modifyMVar_
