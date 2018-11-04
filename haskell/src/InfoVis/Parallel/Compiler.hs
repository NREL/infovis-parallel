{-# LANGUAGE FlexibleContexts #-}


module InfoVis.Parallel.Compiler (
  compileBuffers
) where


import Control.Monad (join)
import Control.Monad.Except (MonadError, MonadIO, liftEither)
import Control.Monad.Log (logInfo)
import Data.ByteString.Lazy (hPut)
import Data.ProtocolBuffers (encodeMessage)
import Data.Serialize (runPutLazy)
import Data.Yaml (decodeFileEither)
import InfoVis (SeverityLog, guardIO)
import InfoVis.Parallel.ProtoBuf (Request)
import System.IO (IOMode(WriteMode), hClose, openFile)


compileBuffers :: (MonadError String m, MonadIO m, SeverityLog m)
               => [FilePath]
               -> FilePath
               -> m ()
compileBuffers inputs output =
  do
    logInfo $ "Opening " ++ show output ++ " . . ."
    handle <- guardIO $ openFile output WriteMode
    sequence_
      [
        do
          logInfo $ "Parsing " ++ show input ++ " . . ."
          result <-
            join
              $ liftEither
              . either (Left . show) Right
              <$> guardIO (decodeFileEither input)
          guardIO
            . hPut handle
            . runPutLazy
            $ encodeMessage (result :: Request)
      |
        input <- inputs
      ]
    logInfo $ "Closing " ++ show output ++ " . . ."
    guardIO $ hClose handle
