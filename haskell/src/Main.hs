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


{-# LANGUAGE ConstraintKinds    #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE FlexibleContexts   #-}
{-# LANGUAGE RecordWildCards    #-}
{-# LANGUAGE StandaloneDeriving #-}

{-# OPTIONS_GHC -fno-warn-orphans #-}


module Main (
  main
) where


import Control.Concurrent
import Control.Monad (when)
import Control.Monad.Except (MonadError, MonadIO, liftIO, runExceptT, throwError)
import Control.Monad.Log (MonadLog, LoggingT, Severity(..), WithSeverity(..), logInfo, renderWithSeverity, runLoggingT)
import Data.ByteString.Base64 (encode)
import Data.Data (Data)
import Data.String (IsString(..))
import Data.Version (showVersion)
import Network.WebSockets
import Paths_infovis_parallel (version)
import System.Console.CmdArgs (Typeable, (&=), Default(..), args, cmdArgs, details, explicit, help, modes, name, program, summary, typ, typFile)
import System.Exit (die)
import System.IO (hPrint, stderr)
import System.IO.Error (tryIOError)

import qualified Data.ByteString as BS
import qualified Data.Text as T


stringVersion :: String
stringVersion = showVersion version ++ ", © 2018"


deriving instance Data Severity


data Infovis =
    SendBuffers
    {
      logging  :: Severity
    , host     :: String
    , port     :: Int
    , path     :: String
    , sendText :: Bool
    , buffers  :: [FilePath]
    }
    deriving (Data, Show, Typeable)


infovis :: Infovis
infovis =
  modes
    [
      sendBuffers
    ]
      &= summary ("Infovis-Parallel command-line, Version " ++ stringVersion ++ " by National Renewable Energy Laboratory")
      &= program "infovis-parallel"
      &= help "This tool provides a command-line interface to Infovis-Parallel."


sendBuffers :: Infovis
sendBuffers =
  SendBuffers
  {
    logging       = Notice
                 &= explicit
                 &= name "logging"
                 &= typ "Debug|Informational|Notice|Warning|Error|Critical"
                 &= help "Level of detail for logging"
  , host          = "127.0.0.1"
                 &= explicit
                 &= name "host"
                 &= typ "ADDRESS"
                 &= help "Address of the websocket server"
  , port          = 8080
                 &= explicit
                 &= name "port"
                 &= typ "PORT"
                 &= help "Port number of the websocket server"
  , path          = "/Infovis"
                 &= explicit
                 &= name "path"
                 &= typ "PATH"
                 &= help "Path for the websocket server"
  , sendText      = False
                 &= explicit
                 &= name "send-text"
                 &= help "Send data as text messages"
  , buffers       = def
                 &= typFile
                 &= args
  }
    &= name "send-buffers"
    &= help "Send protocol buffers serialized as binary files to client."
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
      Left  e  -> die $ "Critical] " ++ e


dispatch :: (MonadError String m, MonadIO m, SeverityLog m)
         => Infovis
         -> m ()

dispatch SendBuffers{..} =
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


type SeverityLog = MonadLog (WithSeverity String)


type SeverityLogT = LoggingT (WithSeverity String)


withSeverityLog :: (MonadError String m, MonadIO m)
                => Severity
                -> SeverityLogT m a
                -> m a
withSeverityLog severity =
  flip runLoggingT
    (
      \message ->
        when (msgSeverity message <= severity)
          $ if msgSeverity message > Critical
              then liftIO . hPrint stderr $ renderWithSeverity fromString message
              else throwError . fromString $ discardSeverity message
    )


guardIO :: (MonadIO m, MonadError String m) => IO a -> m a
guardIO =
  (either (throwError . show) return =<<)
    . liftIO
    . tryIOError
