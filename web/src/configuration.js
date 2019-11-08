
'use strict';


const CONFIGURATION_KEY = "configuration"


function defaultConfiguration(w = window.innerWidth, h = window.innerHeight) {

  const aspect = w / h
  const padding = 1 / 3
  const padding1 = (Math.max(aspect, 1 / aspect) * (1 + 2 * padding) - 1) / 2

  return {
    server : {
      address        : "ws://104.198.152.159:80/infovis/v4/demo"
    }
  , display          : {
      stereo         : false
    , eyeSeparation  : [0.10, 0, 0]
    , nearPlane      : 0.01
    , farPlane       : 100
    , lowerLeft      : aspect > 1 ? [  - padding1,   - padding, 0] : [  - padding,   - padding1, 0]
    , lowerRight     : aspect > 1 ? [1 + padding1,   - padding, 0] : [1 + padding,   - padding1, 0]
    , upperLeft      : aspect > 1 ? [  - padding1, 1 + padding, 0] : [  - padding, 1 + padding1, 0]
    }
  , initial         : {
      view          : {
        position    : [ 3, 2, 15]
      , orientation : [ 0, 0,  0]
      }
    , tool          : {
        position    : [-0.1,  0.5, 0.5]
      , orientation : [ 0  ,-90  , 0  ]
      }
    }
  }

}


let theConfiguration = defaultConfiguration()


function get() {

  const configuration = defaultConfiguration()

  configuration.server.address = uiAddress.value

  configuration.display.stereo    =            uiStereo.checked
  configuration.display.nearPlane = parseFloat(uiNearPlane.value)
  configuration.display.farPlane  = parseFloat(uiFarPlane.value )

  configuration.display.eyeSeparation[0] = parseFloat(uiEyeSeparationX.value)
  configuration.display.eyeSeparation[1] = parseFloat(uiEyeSeparationY.value)
  configuration.display.eyeSeparation[2] = parseFloat(uiEyeSeparationZ.value)

  configuration.display.lowerLeft[0] = parseFloat(uiLowerLeftX.value)
  configuration.display.lowerLeft[1] = parseFloat(uiLowerLeftY.value)
  configuration.display.lowerLeft[2] = parseFloat(uiLowerLeftZ.value)

  configuration.display.lowerRight[0] = parseFloat(uiLowerRightX.value)
  configuration.display.lowerRight[1] = parseFloat(uiLowerRightY.value)
  configuration.display.lowerRight[2] = parseFloat(uiLowerRightZ.value)

  configuration.display.upperLeft[0] = parseFloat(uiUpperLeftX.value)
  configuration.display.upperLeft[1] = parseFloat(uiUpperLeftY.value)
  configuration.display.upperLeft[2] = parseFloat(uiUpperLeftZ.value)

  configuration.initial.view.position   [0] = parseFloat(uiViewPositionX.value   )
  configuration.initial.view.position   [1] = parseFloat(uiViewPositionY.value   )
  configuration.initial.view.position   [2] = parseFloat(uiViewPositionZ.value   )
  configuration.initial.view.orientation[0] = parseFloat(uiViewOrientationX.value)
  configuration.initial.view.orientation[1] = parseFloat(uiViewOrientationY.value)
  configuration.initial.view.orientation[2] = parseFloat(uiViewOrientationZ.value)

  configuration.initial.tool.position   [0] = parseFloat(uiToolPositionX.value   )
  configuration.initial.tool.position   [1] = parseFloat(uiToolPositionY.value   )
  configuration.initial.tool.position   [2] = parseFloat(uiToolPositionZ.value   )
  configuration.initial.tool.orientation[0] = parseFloat(uiToolOrientationX.value)
  configuration.initial.tool.orientation[1] = parseFloat(uiToolOrientationY.value)
  configuration.initial.tool.orientation[2] = parseFloat(uiToolOrientationZ.value)

  theConfiguration = configuration

}


function put() {

  uiAddress.value = theConfiguration.server.address

  uiStereo.checked  = theConfiguration.display.stereo
  uiNearPlane.value = theConfiguration.display.nearPlane
  uiFarPlane.value  = theConfiguration.display.farPlane

  uiEyeSeparationX.value = theConfiguration.display.eyeSeparation[0]
  uiEyeSeparationY.value = theConfiguration.display.eyeSeparation[1]
  uiEyeSeparationZ.value = theConfiguration.display.eyeSeparation[2]

  uiLowerLeftX.value = theConfiguration.display.lowerLeft[0]
  uiLowerLeftY.value = theConfiguration.display.lowerLeft[1]
  uiLowerLeftZ.value = theConfiguration.display.lowerLeft[2]

  uiLowerRightX.value = theConfiguration.display.lowerRight[0]
  uiLowerRightY.value = theConfiguration.display.lowerRight[1]
  uiLowerRightZ.value = theConfiguration.display.lowerRight[2]

  uiUpperLeftX.value = theConfiguration.display.upperLeft[0]
  uiUpperLeftY.value = theConfiguration.display.upperLeft[1]
  uiUpperLeftZ.value = theConfiguration.display.upperLeft[2]

  uiViewPositionX.value    = theConfiguration.initial.view.position   [0]
  uiViewPositionY.value    = theConfiguration.initial.view.position   [1]
  uiViewPositionZ.value    = theConfiguration.initial.view.position   [2]
  uiViewOrientationX.value = theConfiguration.initial.view.orientation[0]
  uiViewOrientationY.value = theConfiguration.initial.view.orientation[1]
  uiViewOrientationZ.value = theConfiguration.initial.view.orientation[2]

  uiToolPositionX.value    = theConfiguration.initial.tool.position   [0]
  uiToolPositionY.value    = theConfiguration.initial.tool.position   [1]
  uiToolPositionZ.value    = theConfiguration.initial.tool.position   [2]
  uiToolOrientationX.value = theConfiguration.initial.tool.orientation[0]
  uiToolOrientationY.value = theConfiguration.initial.tool.orientation[1]
  uiToolOrientationZ.value = theConfiguration.initial.tool.orientation[2]

}


function store() {
  get()
  localStorage.setItem(CONFIGURATION_KEY, JSON.stringify(theConfiguration))
}


function retrieve() {
  theConfiguration = localStorage.getItem(CONFIGURATION_KEY) == null ?
    defaultConfiguration()                                           :
    JSON.parse(localStorage.getItem(CONFIGURATION_KEY))
  put()
}


function load() {
  const input = document.createElement("input")
  input.accept = "application/json"
  input.type = "file"
  input.onchange = (e) => {
    const file = e.target.files[0]
    const reader = new FileReader()
    reader.readAsText(file, "UTF-8")
    reader.onload = (readerEvent) => {
      const content = readerEvent.target.result
      theConfiguration = JSON.parse(content)
      put()
    }
  }
  input.click()
}


function download() {
  uiDownload.href = "data:application/json;charset=utf-8," + encodeURIComponent(JSON.stringify(theConfiguration))
}


module.exports = {
  current  : function() {       return theConfiguration}
, update   : function() {get(); return theConfiguration}
, compute  : function() {theConfiguration = defaultConfiguration(); put()}
, reset    : retrieve
, load     : load
, save     : store
, download : download
}
