// Any copyright is dedicated to the Public Domain.
// http://creativecommons.org/publicdomain/zero/1.0/

/*********************************************
This basic climate example logs a stream
of temperature and humidity to the console.
*********************************************/

var tessel = require('tessel');
var climatelib = require('climate-si7020');
var bleLib = require('ble-ble113a')
var climate = climatelib.use(tessel.port['B']);
var ble = bleLib.use(tessel.port['A']);

ble.on('ready', function(err) {
	if (err) {
		return console.log(err);
	} 
	console.log('Connected to ble113a. ');
	ble.startAdvertising();
});
	
climate.on('ready', function() {
	console.log('Connected to climate-si7020');
});

ble.on('connect', function() {
	console.log("We have a BLE connection to master.");

	setInterval(function(){
		climate.readHumidity(function(err, humid){
			climate.readTemperature('f', function(err, temp){
				var data = "{t: " + temp.toFixed(2) + ", humid: " + humid.toFixed(2) + "}";
				ble.writeLocalValue(0, new Buffer(data));
				console.log('Degrees:', temp.toFixed(4) + 'F', 'Humidity:', humid.toFixed(4) + '%RH');
			});
		});
	}, 1000);


});


climate.on('error', function(err) {
	console.log('error connecting module', err);
});


ble.on('disconnect', function() {
  // Stop our interval
  clearInterval(interval);
  // Start advertising again
  ble.startAdvertising();
});



// var ble = require('../').use(tessel.port['A']); // Replace '../' with 'ble-ble113a' in your own code

// var interval;

// ble.on('ready', function(err) {
// 	if (err) return console.log(err);
//   console.log('started advertising...');
//   ble.startAdvertising();
// });

// ble.on('connect', function() {
//   console.log("We have a connection to master.");
//   var value = 0;
//   interval = setInterval(function iteration() {
//     var str = "Interval #" + value++;
//     console.log("Writing out: ", str);

//     ble.writeLocalValue(0, new Buffer(str));
//   }, 1000);
// });

// ble.on('disconnect', function() {
//   // Stop our interval
//   clearInterval(interval);
//   // Start advertising again
//   ble.startAdvertising();
// });