const CONFIGURATION_KEY = "configuration"


const defaultConfiguration =
  {
    server : {
      address        : "ws://127.0.0.1:42042"
    }
  , display          : {
      stereo         : false
    , eyeSeparation  : [0.10, 0, 0]
    , nearPlane      : 0.01
    , farPlane       : 100
    , lowerLeft      : [-0.50, -0.25, 0  ]
    , lowerRight     : [ 1.50, -0.25, 0  ]
    , upperLeft      : [-0.50,  1.25, 0  ]
    }
  , initial         : {
      view          : {
        position    : [ 0.50,  0.50, 3  ]
      , orientation : [    0,   -90, 0  ]
      }
    , tool          : {
        position    : [-0.1 ,  0.5 , 0.5]
      , orientation : [    0,   -90, 0  ]
      }
    }
  }


var theConfiguration = defaultConfiguration


function get() {

  configuration = defaultConfiguration

  configuration.server.address = uiAddress.value

  configuration.display.stereo    = uiStereo.checked
  configuration.display.nearPlane = uiNearPlane.value
  configuration.display.farPlane  = uiFarPlane.value

  configuration.display.eyeSeparation[0] = uiEyeSeparationX.value
  configuration.display.eyeSeparation[1] = uiEyeSeparationY.value
  configuration.display.eyeSeparation[2] = uiEyeSeparationZ.value

  configuration.display.lowerLeft[0] = uiLowerLeftX.value
  configuration.display.lowerLeft[1] = uiLowerLeftY.value
  configuration.display.lowerLeft[2] = uiLowerLeftZ.value

  configuration.display.lowerRight[0] = uiLowerRightX.value
  configuration.display.lowerRight[1] = uiLowerRightY.value
  configuration.display.lowerRight[2] = uiLowerRightZ.value

  configuration.display.upperLeft[0] = uiUpperLeftX.value
  configuration.display.upperLeft[1] = uiUpperLeftY.value
  configuration.display.upperLeft[2] = uiUpperLeftZ.value

  configuration.initial.view.position[0]    = uiViewPositionX.value
  configuration.initial.view.position[1]    = uiViewPositionY.value
  configuration.initial.view.position[2]    = uiViewPositionZ.value
  configuration.initial.view.orientation[0] = uiViewOrientationX.value
  configuration.initial.view.orientation[1] = uiViewOrientationY.value
  configuration.initial.view.orientation[2] = uiViewOrientationZ.value

  configuration.initial.tool.position[0]    = uiToolPositionX.value
  configuration.initial.tool.position[1]    = uiToolPositionY.value
  configuration.initial.tool.position[2]    = uiToolPositionZ.value
  configuration.initial.tool.orientation[0] = uiToolOrientationX.value
  configuration.initial.tool.orientation[1] = uiToolOrientationY.value
  configuration.initial.tool.orientation[2] = uiToolOrientationZ.value

  theConfiguration = configuration

}


function put() {

  configuration = theConfiguration

  uiAddress.value = configuration.server.address

  uiStereo.checked  = configuration.display.stereo
  uiNearPlane.value = configuration.display.nearPlane
  uiFarPlane.value  = configuration.display.farPlane

  uiEyeSeparationX.value = configuration.display.eyeSeparation[0]
  uiEyeSeparationY.value = configuration.display.eyeSeparation[1]
  uiEyeSeparationZ.value = configuration.display.eyeSeparation[2]

  uiLowerLeftX.value = configuration.display.lowerLeft[0]
  uiLowerLeftY.value = configuration.display.lowerLeft[1]
  uiLowerLeftZ.value = configuration.display.lowerLeft[2]

  uiLowerRightX.value = configuration.display.lowerRight[0]
  uiLowerRightY.value = configuration.display.lowerRight[1]
  uiLowerRightZ.value = configuration.display.lowerRight[2]

  uiUpperLeftX.value = configuration.display.upperLeft[0]
  uiUpperLeftY.value = configuration.display.upperLeft[1]
  uiUpperLeftZ.value = configuration.display.upperLeft[2]

  uiViewPositionX.value    = configuration.initial.view.position[0]
  uiViewPositionY.value    = configuration.initial.view.position[1]
  uiViewPositionZ.value    = configuration.initial.view.position[2]
  uiViewOrientationX.value = configuration.initial.view.orientation[0]
  uiViewOrientationY.value = configuration.initial.view.orientation[1]
  uiViewOrientationZ.value = configuration.initial.view.orientation[2]

  uiToolPositionX.value    = configuration.initial.tool.position[0]
  uiToolPositionY.value    = configuration.initial.tool.position[1]
  uiToolPositionZ.value    = configuration.initial.tool.position[2]
  uiToolOrientationX.value = configuration.initial.tool.orientation[0]
  uiToolOrientationY.value = configuration.initial.tool.orientation[1]
  uiToolOrientationZ.value = configuration.initial.tool.orientation[2]

}


function store() {
  get()
  localStorage.setItem(CONFIGURATION_KEY, JSON.stringify(theConfiguration))
}


function retrieve() {
  configuration = JSON.parse(localStorage.getItem(CONFIGURATION_KEY))
  if (configuration == null)
    configuration = defaultConfiguration
  theConfiguration = configuration
  put()
}


function load() {
  var input = document.createElement("input")
  input.type = "file"
  input.onchange = e => {
    var file = e.target.files[0]
    var reader = new FileReader()
    reader.readAsText(file, "UTF-8")
    reader.onload = readerEvent => {
      var content = readerEvent.target.result
      theConfiguration = JSON.parse(content)
      put()
    }
  }
  input.click()
}


module.exports = {
  current : function() {       return theConfiguration}
, update  : function() {get(); return theConfiguration}
, reset   : retrieve
, load    : load
, save    : store
}
