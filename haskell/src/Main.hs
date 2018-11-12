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
import System.Console.CmdArgs (Typeable, (&=), args, cmdArgs, details, explicit, help, modes, name, program, summary, typ, typFile)
import System.Exit (die)

import qualified InfoVis.Parallel.Compiler as I (compileBuffers)
import qualified InfoVis.Parallel.Sender as I (sendBuffers)


deriving instance Data Severity


data InfoVis =
    SendBuffers
    {
      logging  :: Severity
    , host     :: String
    , port     :: Int
    , path     :: String
    , sendText :: Bool
    , buffers  :: [FilePath]
    }
  | Compile
    {
      logging  :: Severity
    , buffers  :: [FilePath]
    , output   :: FilePath
    }
    deriving (Data, Show, Typeable)


infovis :: InfoVis
infovis =
  modes
    [
      sendBuffers
    , compile
    ]
      &= summary ("InfoVis-Parallel command line, Version " ++ stringVersion ++ " by National Renewable Energy Laboratory")
      &= program "infovis-parallel"
      &= help "This tool provides a command-line interface to InfoVis-Parallel."


sendBuffers :: InfoVis
sendBuffers =
  SendBuffers
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
  , port      = 8080
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
    &= name "send"
    &= help "Send protocol buffers serialized as binary files to client."
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
dispatch SendBuffers{..} = I.sendBuffers host port path sendText buffers
dispatch Compile{..} = I.compileBuffers buffers output