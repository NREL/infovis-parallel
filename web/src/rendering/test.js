
function drawText(text) {
//preservingMatrix
//  $ do
//    (_, Size w h) <- get viewport
//    matrixMode $=! Projection
//    loadIdentity
//    fh <- fontHeight MonoRoman
//    color (Color4 1 1 0 0.5 :: Color4 Double)
//    toTranslation (V3 (-0.975) 0.9 0 :: V3 Double)
//    toScale $ V3 (fromIntegral h / fromIntegral w * 0.1 / fh) (0.1 / fh) 1
//    renderString MonoRoman text
}


module.exports = {
  drawText : drawText
}
