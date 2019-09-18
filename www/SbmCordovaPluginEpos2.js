var exec = require('cordova/exec');

module.exports.coolMethod = function (arg0, success, error) {
    exec(success, error, 'SbmCordovaPluginEpos2', 'coolMethod', [arg0]);
};

module.exports.discoverPrinters = function (arg0, success, error) {
    exec(success, error, 'SbmCordovaPluginEpos2', 'discoverPrinters', [arg0]);
};

module.exports.printText = function (arg0, success, error) {
    exec(success, error, 'SbmCordovaPluginEpos2', 'printText', [arg0]);
};


module.exports.stopDiscoverPrinters = function (arg0, success, error) {
    exec(success, error, 'SbmCordovaPluginEpos2', 'stopDiscoverPrinters', [arg0]);
};


module.exports.getPrintersList = function (arg0, success, error) {
    exec(success, error, 'SbmCordovaPluginEpos2', 'getPrintersList', [arg0]);
};




