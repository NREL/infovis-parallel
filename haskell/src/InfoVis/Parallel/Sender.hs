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


{-# LANGUAGE FlexibleContexts   #-}


module InfoVis.Parallel.Sender (
  sendBuffers
) where


import Control.Concurrent (threadDelay)
import Control.Monad.Except (MonadError, MonadIO)
import Control.Monad.Log (logInfo)
import Data.ByteString.Base64 (encode)
import InfoVis (SeverityLog, guardIO)
import Network.WebSockets (runClient, sendBinaryData, sendTextData, sendClose)

import qualified Data.ByteString as BS (readFile)
import qualified Data.Text as T (pack)




sendBuffers :: (MonadError String m, MonadIO m, SeverityLog m)
            => String
            -> Int
            -> String
            -> Bool
            -> [FilePath]
            -> m ()
sendBuffers host port path sendText buffers =
  do
    logInfo $ "Opening WebSocket on <ws://" ++ host ++ ":" ++ show port ++ path ++ "> . . ."
    guardIO
      . runClient host port path
      $ \connection ->
      do
        sequence_
          [
            do
              bytes <- BS.readFile file
              if sendText
                then sendBinaryData connection bytes
                else sendTextData connection $ encode bytes
          |
            file <- buffers
          ]
        threadDelay 500000
        sendClose connection $ T.pack "Infovis done."
    logInfo $ "Closing WebSocket on <ws://" ++ host ++ ":" ++ show port ++ path ++ "> . . ."
