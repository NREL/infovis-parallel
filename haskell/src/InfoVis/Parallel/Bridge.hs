-----------------------------------------------------------------------------
--
-- Module      :  $Headers
-- Copyright   :  (c) 2018 National Renewable Energy Laboratory
-- License     :  All Rights Reserved
--
-- Maintainer  :  Brian W Bush <brian.bush@nrel.gov>
-- Stability   :  Stable
-- Portability :  Portable
--
-- | Sending buffers to Infovis-Parallel servers over WebSockets.
--
-----------------------------------------------------------------------------


{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE FlexibleInstances #-}


module InfoVis.Parallel.Bridge (
  bridgeKafka
) where


import Control.Concurrent (threadDelay)
import Control.Monad.Except (MonadError, MonadIO)
import Control.Monad.Log (Severity(..), logInfo)
import InfoVis (SeverityLog, withLogger)
import Network.WebSockets (acceptRequest, runServer, sendBinaryData)

import qualified Data.ByteString as BS (readFile)


bridgeKafka :: (MonadError String m, MonadIO m, SeverityLog m)
            => String
            -> Int
            -> [FilePath]
            -> m ()
bridgeKafka host port buffers =
  do
    logInfo $ "Serving WebSockets on <ws://" ++ host ++ ":" ++ show port ++ "> . . ."
    withLogger $ \logger ->
      runServer host port
        $ \pending ->
        do
          connection <- acceptRequest pending
          sequence_
            [
              do
                logger Debug $ "Reading " ++ show file ++ " . . ."           
                bytes <- BS.readFile file
                logger Informational $ "Sending " ++ show file ++ " . . ."           
                sendBinaryData connection bytes
            |
              file <- buffers
            ]
          threadDelay maxBound
