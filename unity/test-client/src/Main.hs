module Main (
  main
) where


import Control.Concurrent
import Data.ByteString.Base64 (encode)
import Network.WebSockets
import System.Environment

import qualified Data.ByteString as BS
import qualified Data.Text as T


useBinary :: Bool
useBinary = True


main :: IO ()
main =
  do
    host : files <- getArgs
    runClient host {- 192.168.86.157 -} 8080 "/Infovis"
      $ \connection ->
      do
        sequence_
          [
            do
              bytes <- BS.readFile file
              if useBinary
                then sendBinaryData connection bytes
                else sendTextData connection $ encode bytes
          |
            file <- files
          ]
        threadDelay 500000
        sendClose connection $ T.pack "Done."
