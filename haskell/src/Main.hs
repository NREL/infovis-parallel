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
-- | Command-line tool for InfoVis-Parallel.
--
-----------------------------------------------------------------------------


{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleContexts   #-}
{-# LANGUAGE RecordWildCards    #-}
{-# LANGUAGE StandaloneDeriving #-}

{-# OPTIONS_GHC -fno-warn-missing-fields #-}
{-# OPTIONS_GHC -fno-warn-orphans        #-}


module Main (
  main
) where


import Control.Monad.Except (MonadError, MonadIO, runExceptT)
import Control.Monad.Log (Severity(..))
import Data.Data (Data)
import InfoVis (SeverityLog, stringVersion, withSeverityLog)
import System.Console.CmdArgs (Typeable, (&=), argPos, args, cmdArgs, details, explicit, help, modes, name, program, summary, typ, typFile)
import System.Exit (die)

import qualified InfoVis.Parallel.Compiler        as I (compileBuffers)
import qualified InfoVis.Parallel.KafkaSender     as I (sendKafka)
import qualified InfoVis.Parallel.KafkaMultiplex  as I (multiplexKafka)
import qualified InfoVis.Parallel.WebsocketSender as I (sendBuffers)
import qualified InfoVis.Parallel.Visualizer      as I (visualizeBuffers)


deriving instance Data Severity


data InfoVis =
    SendWebsocket
    {
      logging  :: Severity
    , host     :: String
    , port     :: Int
    , path     :: String
    , sendText :: Bool
    , buffers  :: [FilePath]
    }
  | SendKafka
    {
      logging  :: Severity
    , host     :: String
    , port     :: Int
    , client   :: String
    , topic    :: String
    , buffers  :: [FilePath]
    }
  | MultiplexKafka
    {
      logging  :: Severity
    , host     :: String
    , port     :: Int
    , client   :: String
    , topic    :: String
    , configs  :: [FilePath]
    }
  | Compile
    {
      logging  :: Severity
    , buffers  :: [FilePath]
    , output   :: FilePath
    }
  | Visualize
    {
      logging  :: Severity
    , config   :: FilePath
    , buffers  :: [FilePath]
    }
    deriving (Data, Show, Typeable)


infovis :: InfoVis
infovis =
  modes
    [
      sendWebsocket
    , sendKafka
    , multiplexKafka
    , compile
    , visualize
    ]
      &= summary ("InfoVis-Parallel command line, Version " ++ stringVersion ++ " by National Renewable Energy Laboratory")
      &= program "infovis-parallel"
      &= help "This tool provides a command-line interface to InfoVis-Parallel."


sendWebsocket :: InfoVis
sendWebsocket =
  SendWebsocket
  {
    logging   = Informational
             &= explicit
             &= name "logging"
             &= typ "LEVEL"
             &= help "Minimum level of detail for logging: one of Debug, Informational, Notice, Warning, Error"
  , host      = "127.0.0.1"
             &= explicit
             &= name "host"
             &= typ "ADDRESS"
             &= help "Address of the websocket server"
  , port      = 9092
             &= explicit
             &= name "port"
             &= typ "PORT"
             &= help "Port number of the websocket server"
  , path      = "/InfoVis"
             &= explicit
             &= name "path"
             &= typ "PATH"
             &= help "Path for the websocket server"
  , sendText  = False
             &= explicit
             &= name "text"
             &= help "Send data as text messages"
  , buffers   = []
             &= typFile
             &= args
  }
    &= explicit
    &= name "websocket"
    &= help "Send protocol buffers serialized as binary files to client."
    &= details []


sendKafka :: InfoVis
sendKafka =
  SendKafka
  {
    client  = "requester"
           &= explicit
           &= name "client"
           &= typ "NAME"
           &= help "Name for Kafka client"
  , topic   = "requests"
           &= explicit
           &= name "topic"
           &= help "Name of Kafka topic"
  }
    &= explicit
    &= name "send"
    &= help "Send protocol buffers serialized as binary files to Kafka topic."
    &= details []


multiplexKafka :: InfoVis
multiplexKafka =
  MultiplexKafka
  {
    configs  = []
           &= typ "YAML"
           &= args
  }
    &= explicit
    &= name "multiplex"
    &= help "Combine multiple Kafka streams of protocol buffers."
    &= details []


compile :: InfoVis
compile =
  Compile
  {
    output  = "/dev/stdout"
           &= explicit
           &= name "output"
           &= typFile
           &= help "Serialized protocol buffers"
  }
    &= explicit
    &= name "compile"
    &= help "Compile YAML files to serialized protocol buffers."
    &= details []


visualize :: InfoVis
visualize =
  Visualize
  {
    config  = "config.yaml"
           &= typ "YAML"
           &= argPos 0
  }
    &= explicit
    &= name "visualize"
    &= help "Visualize protocol buffers serialized as binary files."
    &= details []


main :: IO ()
main =
  do
    command <- cmdArgs infovis
    result <-
      runExceptT
        . withSeverityLog (logging command)
        $ dispatch command
    case result :: Either String () of
      Right () -> return ()
      Left  e  -> die $ "[Critical] " ++ e


dispatch :: (MonadError String m, MonadIO m, SeverityLog m)
         => InfoVis
         -> m ()
dispatch SendWebsocket{..} = I.sendBuffers host port path sendText buffers
dispatch SendKafka{..} = I.sendKafka (host, port) client topic buffers
dispatch MultiplexKafka{..} = I.multiplexKafka (host, port) client topic configs
dispatch Compile{..} = I.compileBuffers buffers output
dispatch Visualize{..} = I.visualizeBuffers config (logging == Debug) buffers
