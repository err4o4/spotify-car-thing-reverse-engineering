
Allows **ESP32s3** act as WiFi dongle for superbird

Run install script `install_esp_idf.sh`
	
	chmod +x install_esp_idf.sh
	./install_esp_idf.sh
	cd ./esp-idf
	. ./export.sh

Go to examples and find tusb_ncm

	cd ./examples/peripherals/usb/device/tusb_ncm/
	
Set wifi config

	idf.py set-target esp32s3
	idf.py menuconfig

Set the Wi-Fi configuration in the `Example Configuration` menu:

Set `WiFi SSID`.
Set `WiFi Password`.

Build and flash
	
	idf.py -p /dev/ttyACM0 build flash monitor
	
Connect usb-otg to esp32. [Pin assignment](https://github.com/espressif/esp-idf/blob/master/examples/peripherals/usb/README.md#common-pin-assignments)

Don't forget to set `network=eth` in `/boot/bootargs.txt` 
