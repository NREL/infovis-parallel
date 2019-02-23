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


{-# LANGUAGE ExplicitForAll    #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE RecordWildCards   #-}


module InfoVis.Parallel.KafkaSender (
  sendKafka
) where


import Control.Concurrent.Chan (Chan, newChan)
import Control.Monad (void)
import Control.Monad.Except (MonadError, MonadIO)
import InfoVis (SeverityLog, forkLoggedIO, guardIO, logIO, makeLogger)
import InfoVis.Parallel.ProtoBuf (Request)
import InfoVis.Parallel.ProtoBuf.Sink (kafkaSink)
import InfoVis.Parallel.ProtoBuf.Source (filesSource, waitForever)
import Network.UI.Kafka (TopicConnection(..))


sendKafka :: forall m . (MonadError String m, MonadIO m, SeverityLog m)
            => (String, Int)
            -> String
            -> String
            -> [FilePath]
            -> m ()
sendKafka address client topic files =
  do

    (logChannel, logger) <- makeLogger

    requestChannel  <- guardIO newChan

    void
      . forkLoggedIO logChannel
      $ do
        filesSource requestChannel files
        waitForever (requestChannel :: Chan Request)
        return False

    void
      . forkLoggedIO logChannel
      $ do
        kafkaSink (logIO logChannel) requestChannel TopicConnection{..}
        return True

    logger
