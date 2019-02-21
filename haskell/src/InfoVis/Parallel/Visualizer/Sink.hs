{-# LANGUAGE FlexibleContexts #-}


module InfoVis.Parallel.Visualizer.Sink (
  deviceSink
) where


import Control.Concurrent.Chan (Chan, readChan)
import Control.Monad (forever, void)
import Control.Monad.Except (MonadError, MonadIO)
import Control.Monad.Log (logDebug)
import InfoVis (SeverityLog, guardIO)
import InfoVis.Parallel.ProtoBuf (Response)


deviceSink :: (MonadError String m, MonadIO m, SeverityLog m)
           => Chan Response
           -> m ()
deviceSink responseChannel =
  void
    . forever
    $ do
        response <-
          guardIO
            $ readChan responseChannel
        logDebug $ "Response: " ++ show response
