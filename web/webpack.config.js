const path = require('path')

module.exports = {
  entry           : './src/controller.js'
, mode            : 'production'
, output          : {
    filename      : 'controller.js'
  , path          : path.resolve(__dirname, '.')
  , libraryTarget : "var"
  , library       : "Controller"
  }
}
