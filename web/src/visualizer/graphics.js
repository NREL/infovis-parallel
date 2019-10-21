
////const Rendering = {
////  Frames   : require("../rendering/frames"  )
////, Selector : require("../rendering/selector")
////}


function initialize(gl, initialViewer, initialTool) {
  const manager = Rendering.Frames.createManager(gl)
  return {
    startRef    : null
  , lockRef     : null
  , managerRef  : manager
  , selectorRef : Rendering.Selector.createSelector(gl, manager.program)
  , povRef      : [initialViewer[0], fromEulerd(initialViewer[1])]
  , toolRef     : [initalTool   [0], fromEulerd(initialTool  [1])]
  , textRef     : ""
  , offsetRef   : [zero, fromEulerd(zero)]
  }
}


function visualize(gl, viewer, initialViewer, initialTool, debug, logChannel, requestChannel, responseChannel) {

  const graphics = initialize(initialViewer, initialTool) 

}

////    void
////      . forkLoggedIO logChannel
////      $ do
////        guardIO $ takeMVar $ startRef graphics
////        apply graphics requestChannel
////        return False
////
////    logInfo "Forking OpenGL . . ."
////    void
////      . forkLoggedOS logChannel
////      . guardIO
////      $ do
////        display (logIO logChannel) debug viewer graphics responseChannel
////        return True
////
////
////apply :: (MonadError String m, MonadIO m, SeverityLog m)
////      => Graphics
////      -> Chan Request
////      -> m ()
////apply Graphics{..} requestChannel =
////  let
////    conditionally f g x = if f x then g x else id
////    onlyJust v = maybe (return ()) (void . swapMVar v)
////  in
////    guardIO
////      . forever
////      $ do
////        request <- readChan requestChannel
////        void $ takeMVar lockRef
////        manager <- readMVar managerRef
////        void
////          . swapMVar managerRef
////          . delete                                 (request ^. P.delete   )
////          . insert                                 (request ^. P.upsert   )
////          . conditionally id     (const reset)     (request ^. P.reset    )
////          . conditionally (/= 0) (currentFrame .~) (request ^. P.frameShow)
////          $ manager
////        putMVar lockRef ()
////        onlyJust povRef    $ request ^. P.viewSet
////        onlyJust toolRef   $ request ^. P.toolSet
////        onlyJust textRef   $ request ^. P.display
////        onlyJust offsetRef $ request ^. P.offsetSet
////
////
////display :: LoggerIO
////        -> Bool
////        -> Viewer Double
////        -> Graphics
////        -> Chan Event
////        -> IO ()
////display logger debug viewer Graphics{..} responseChannel =
////  do
////
////    logger Debug "Initializing OpenGL . . ."
////    dlp <-
////      setup 
////        (if debug then Just (logger Debug . show) else Nothing)
////        "InfoVis Parallel"
////        "InfoVis Parallel"
////        viewer
////
////    logger Debug "Creating array buffer manager . . ."
////    createManager
////      >>= putMVar managerRef
////    createSelector
////      .   program
////      <$> readMVar managerRef
////      >>= putMVar selectorRef
////    lockRef `putMVar` ()
////
////    idle Graphics{..} responseChannel
////
////    logger Debug "Setting up display . . ."
////    dlpViewerDisplay dlp viewer (readMVar povRef)
////      $ do
////        (P translation, rotation) <- readMVar offsetRef
////        toTranslation translation
////        toRotation    rotation
////        readMVar managerRef  >>= draw
////        readMVar selectorRef >>= drawSelector
////        readMVar textRef     >>= drawText
////
////    setCallbacks [minBound..maxBound]
////      $ writeChan responseChannel
////
////    idleCallback $=! Just (idle Graphics{..} responseChannel)
////
////#ifdef INFOVIS_SWAP_GROUP
////    logger Debug "Joining swap group . . ."
////    void
////      $  maybe (return False) joinSwapGroup useSwapGroup
////#endif
////
////    logger Debug "Starting main loop . . ."
////    mainLoop
////
////
////idle :: Graphics
////     -> Chan Event
////     -> IdleCallback
////idle Graphics{..} _responseChannel =
////  do
////    void
////      $ tryPutMVar startRef ()
////    tool <- readMVar toolRef
////    lock <- tryTakeMVar lockRef
////    when (isJust lock)
////      $ do
////        void
////          $   readMVar managerRef
////          >>= prepare
////          >>= swapMVar managerRef
////        void
////          $   readMVar selectorRef
////          >>= prepareSelector tool
////          >>= swapMVar selectorRef
////        lockRef `putMVar` ()
////    postRedisplay Nothing
}


module.exports = {
  visualize : visualize
}
