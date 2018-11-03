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
{-# LANGUAGE RecordWildCards    #-}


module Main (
  main
) where


import Control.Concurrent
import Data.ByteString.Base64 (encode)
import Data.Data (Data)
import Data.Version (showVersion)
import Network.WebSockets
import Paths_infovis_parallel (version)
import System.Console.CmdArgs (Typeable, (&=), Default(..), args, cmdArgs, details, explicit, help, modes, name, program, summary, typ, typFile)

import qualified Data.ByteString as BS
import qualified Data.Text as T


stringVersion :: String
stringVersion = showVersion version ++ ", © 2018"


data Infovis =
    SendBuffers
    {
      host         :: String
    , port         :: Int
    , path         :: String
    , buffers      :: [FilePath]
    , sendText :: Bool
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
    host          = "127.0.0.1"
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
  , buffers       = def
                 &= typFile
                 &= args
  , sendText      = False
                 &= explicit
                 &= name "send-text"
                 &= help "Send data as text messages"
  }
    &= name "send-buffers"
    &= help "Send protocol buffers serialized as binary files to client."
    &= details []


main :: IO ()
main =
  do
    command <- cmdArgs infovis
    dispatch command


dispatch :: Infovis -> IO ()

dispatch SendBuffers{..} =
  runClient host port path
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
      sendClose connection $ T.pack "Done."
