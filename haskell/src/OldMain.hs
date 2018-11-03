{-# LANGUAGE DeriveDataTypeable          #-}
{-# LANGUAGE RecordWildCards             #-}

{-# OPTIONS_GHC -fno-warn-missing-fields #-}


module Main (
  main
) where


import Control.Distributed.Process.Node (initRemoteTable)
import Data.Data (Data)
import Data.Default (def)
import Data.Typeable (Typeable)
import Data.Version (showVersion)
import Data.Yaml.Config (loadYamlSettings, ignoreEnv)
import InfoVis.Parallel.Types.Configuration (Configuration(advanced), peersList)
import Paths_infovis_parallel (version)
import System.Console.CmdArgs ((&=), args, cmdArgs, details, help, modes, name, program, summary, typ, typFile)

import qualified Control.Distributed.Process.Backend.SimpleLocalnet as L (initializeBackend, startMaster)
import qualified Control.Distributed.Process.Backend.SimpleWidenet as W (initializeBackend, startMaster, startSlave)
import qualified InfoVis.Parallel.Process as P (__remoteTable, masterMain, soloMain)


{-# ANN module "HLint: ignore Reduce duplication" #-}


data InfoVisParallel =
    Master
    {
      host    :: String
    , port    :: String
    , configs :: [FilePath]
    }
  | Slave
    {
      host    :: String
    , port    :: String
    }
  | Solo
    {
      configs :: [FilePath]
    }
      deriving (Data, Show, Typeable)


infoVisParallel :: InfoVisParallel
infoVisParallel =
  modes
    [
      master
    , slave
    , solo
    ]
    &= summary ("Information Visualization in Parallel, Version " ++ showVersion version ++ " © 2015-17 National Renewable Energy Laboratory, All Rights Reserved")
    &= program "infovis-parallel"
    &= help "Information visualization in parallel."


master :: InfoVisParallel
master =
  Master
  {
    host     = def
            &= typ "HOST"
            &= help "The host name (default localhost)."
  , port     = def
            &= typ "PORT"
            &= help "The port number (default 44444)."
  , configs  = def
            &= typFile
            &= args
  }
    &= name "master"
    &= help "Master process for information visualization in parallel."
    &= details ["FIXME: Add details here."]


slave :: InfoVisParallel
slave =
  Slave
  {
  }
    &= name "slave"
    &= help "Slave process for information visualization in parallel."
    &= details ["FIXME: Add details here."]


solo :: InfoVisParallel
solo =
  Solo
  {
  }
    &= name "solo"
    &= help "Locally run information visualization in parallel."
    &= details ["FIXME: Add details here."]


main :: IO ()
main = dispatch =<< cmdArgs infoVisParallel


dispatch :: InfoVisParallel -> IO ()
dispatch Master{..} =
  do
    configuration <- loadYamlSettings configs [] ignoreEnv
    let
      host' = if null host then "localhost" else host
      port' = if null port then "44444"     else port
      rtable = P.__remoteTable initRemoteTable
      configuration' = maybe (configuration {advanced = Just def}) (const configuration) $ advanced configuration
    backend <- W.initializeBackend (peersList configuration) host' port' rtable
    (`W.startMaster` P.masterMain configuration') backend
dispatch Slave{..} =
  do
    let
      host' = if null host then "localhost" else host
      port' = if null port then "44444"     else port
      rtable = P.__remoteTable initRemoteTable
    backend <- W.initializeBackend [] host' port' rtable
    W.startSlave backend
dispatch Solo{..} =
  do
    configuration <- loadYamlSettings configs [] ignoreEnv
    let
      rtable = P.__remoteTable initRemoteTable
      configuration' = maybe (configuration {advanced = Just def}) (const configuration) $ advanced configuration
    backend <- L.initializeBackend "localhost" "44444" rtable
    (`L.startMaster` P.soloMain configuration') backend
