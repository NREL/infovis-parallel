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
-- | General types and functions for InfoVis-Parallel.
--
-----------------------------------------------------------------------------


{-# LANGUAGE ConstraintKinds    #-}
{-# LANGUAGE FlexibleContexts   #-}


module InfoVis (
  SeverityLog
, SeverityLogT
, withSeverityLog
, withLogger
, LogChannel
, makeLogger
, forkLoggedIO
, forkLoggedOS
, LoggerIO
, logIO
, guardIO
, stringVersion
) where


import Control.Concurrent (ThreadId, forkIO, forkOS)
import Control.Concurrent.Chan (Chan, newChan, readChan, writeChan)
import Control.Concurrent.MVar (newEmptyMVar, putMVar, takeMVar)
import Control.Exception (SomeException, catch)
import Control.Monad (void, when)
import Control.Monad.Except (ExceptT, MonadError, MonadIO, liftIO, runExceptT, throwError)
import Control.Monad.Log (MonadLog, LoggingT, Severity(..), WithSeverity(..), logMessage, renderWithSeverity, runLoggingT)
import Data.String (IsString(..))
import Data.Version (showVersion)
import Paths_infovis_parallel (version)
import System.IO (hPrint, stderr)
import System.IO.Error (tryIOError)


stringVersion :: String
stringVersion = showVersion version ++ ", © 2019"


type SeverityLog = MonadLog (WithSeverity String)


type SeverityLogT = LoggingT (WithSeverity String)


withSeverityLog :: (MonadError String m, MonadIO m)
                => Severity
                -> SeverityLogT m a
                -> m a
withSeverityLog severity =
  flip runLoggingT
    $ \message ->
      when (msgSeverity message <= severity)
        . liftIO
        . hPrint stderr
        $ renderWithSeverity fromString message


withLogger :: (MonadError String m, MonadIO m, SeverityLog m)
           => ((Severity -> String -> IO ()) -> IO a)
           -> m a
withLogger action =
  do
    resultRef <- liftIO newEmptyMVar
    (logChannel, logger) <- makeLogger
    void
      . forkLoggedIO logChannel
      . guardIO
      $ do
        result <- action $ logIO logChannel
        putMVar resultRef result
        return True
    logger
    liftIO
      $ takeMVar resultRef


type LoggerIO =  Severity
              -> String
              -> IO ()


logIO :: LogChannel
      -> LoggerIO
logIO logChannel = ((writeChan logChannel . Message) .) . WithSeverity


type LogChannel = Chan Logger


data Logger =
    Message (WithSeverity String)
  | Completed Bool
  | Failed String
    

makeLogger :: (MonadError String m, MonadIO m, SeverityLog m)
           => m (LogChannel, m ())
makeLogger =
  do
    logChannel <- liftIO newChan
    return
      (
        logChannel
      , let
          loop =
            do
              info <- liftIO $ readChan logChannel
              case info of
                Message message -> logMessage message >> loop
                Completed False -> loop
                Completed True  -> return ()
                Failed err      -> throwError $ show err
        in
          loop
      )


forkLoggedIO :: (MonadError String m, MonadIO m, SeverityLog m)
             => LogChannel
             -> SeverityLogT (ExceptT String IO) Bool
             -> m ThreadId
forkLoggedIO = forkLogged forkIO


forkLoggedOS :: (MonadError String m, MonadIO m, SeverityLog m)
             => LogChannel
             -> SeverityLogT (ExceptT String IO) Bool
             -> m ThreadId
forkLoggedOS = forkLogged forkOS


forkLogged :: (MonadError String m, MonadIO m, SeverityLog m)
           => (IO () -> IO ThreadId)
           -> LogChannel
           -> SeverityLogT (ExceptT String IO) Bool
           -> m ThreadId
forkLogged forker logChannel action =
    liftIO
      . forker
      $ writeChan logChannel
      =<< catch
          (
            either Failed Completed
              <$> runExceptT
              (runLoggingT action $ liftIO . writeChan logChannel . Message)
          )
          (return . Failed . (show :: SomeException -> String))
  


guardIO :: (MonadIO m, MonadError String m)
        => IO a
        -> m a
guardIO =
  (either (throwError . show) return =<<)
    . liftIO
    . tryIOError
