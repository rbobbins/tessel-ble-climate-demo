var tessel = require('tessel');

var climatelib = require('climate-si7020');
var bleLib = require('ble-ble113a')

var climate = climatelib.use(tessel.port['B']);
var ble = bleLib.use(tessel.port['A']);


ble.on('ready', function(err) {
	if (err) {
		return console.log(err);
	} 
	console.log('Connected to ble113a.');

	ble.startAdvertising();
});


ble.on('connect', function() {
	console.log("We have a BLE connection to master.");

	setInterval(function(){
		climate.readHumidity(function(err, humid){
			climate.readTemperature('f', function(err, temp){
				ble.writeLocalValue(0, new Buffer(temp.toFixed(4)));
				ble.writeLocalValue(1, new Buffer(humid.toFixed(4)));
			});
		});
	}, 1000);
});

//Climate event handling, primarily logging
climate.on('ready', function() {
	console.log('Connected to climate-si7020');
});

climate.on('error', function(err) {
	console.log('error connecting module', err);
});


//Bluetooth event handling, primarily logging
ble.on('disconnect', function() {
	console.log('Disconnected from central device')
  // Stop our interval
  clearInterval(interval);
  // Start advertising again
  ble.startAdvertising();
});

ble.on('startAdvertising', function(){
	console.log('Started advertising as BLE peripheral device')
});

ble.on('stopAdvertising', function(){
	console.log('Stopped advertising')
});

