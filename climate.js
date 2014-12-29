var tessel = require('tessel');
var packetGen = require('bleadvertise');

// Load and immediately run tesselate module
require('tesselate')({
  modules: {
    A: ['ble-ble113a', 'ble'],
    B: ['climate-si7020', 'climate']
  },
  development: true              // enable development logging, useful for debugging
}, function(tessel, modules){
  var ble = modules.ble;
  var climate = modules.climate;

    console.log('Connected to modules.');
    ble.setAdvertisingData(packetGen.serialize({completeName: "Tessel BLE113A Module"}), function(err) {
      if (err) {
        return console.log(err);
      }
      ble.startAdvertising();
    })


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
});