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
-- | Sending buffers to Infovis-Parallel servers over Kafka.
--
-----------------------------------------------------------------------------


{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RecordWildCards   #-}


module InfoVis.Parallel.KafkaSender (
  sendKafka
) where


import Control.Monad.Except (MonadError, MonadIO)
import Control.Monad.Log (Severity(..), logInfo)
import InfoVis (SeverityLog, withLogger)
import Network.Kafka.Producer (makeMessage)
import Network.UI.Kafka (TopicConnection(..), rawProducerLoop)

import qualified Data.ByteString as BS (readFile)


sendKafka :: (MonadError String m, MonadIO m, SeverityLog m)
            => (String, Int)
            -> String
            -> String
            -> [FilePath]
            -> m ()
sendKafka address@(host, port) client topic buffers =
  do
    logInfo $ "Opening Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " . . ."
    withLogger $ \logger ->
      do
        (_, loop) <-
          rawProducerLoop
            TopicConnection{..}
            makeMessage
          $ sequence
          [
            do
              logger Debug $ "Reading " ++ show file ++ " . . ."           
              bytes <- BS.readFile file
              logger Informational $ "Sending " ++ show file ++ " . . ."           
              return bytes
          |
            file <- buffers
          ]
        loop
    logInfo $ "Closing connection to Kafka topic " ++ topic ++ " on " ++ host ++ ":" ++ show port ++ " . . ."
