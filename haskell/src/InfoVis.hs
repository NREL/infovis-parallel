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
, guardIO
, stringVersion
) where


import Control.Concurrent (forkIO)
import Control.Concurrent.Chan (newChan, readChan, writeChan)
import Control.Exception (SomeException, catch)
import Control.Monad (void, when)
import Control.Monad.Except (MonadError, MonadIO, liftIO, throwError)
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
    messages <- liftIO newChan
    void
      . liftIO
      . forkIO
      $ do
        result <- catch
                    (fmap Right . action $ ((writeChan messages . Right) .) . (,))
                    (\e -> return $ Left (e :: SomeException))
        writeChan messages $ Left result        
    let
      loop =
        do
          info <- liftIO $ readChan messages
          case info of
            Right (severity, message) -> logMessage (WithSeverity severity message) >> loop
            Left  (Right result     ) -> return result
            Left  (Left  err        ) -> throwError $ show err
    loop


guardIO :: (MonadIO m, MonadError String m) => IO a -> m a
guardIO =
  (either (throwError . show) return =<<)
    . liftIO
    . tryIOError
