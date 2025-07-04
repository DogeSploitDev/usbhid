echo 0x1d6b > idVendor
echo 0x0104 > idProduct
mkdir strings/0x409
echo "0123456789" > strings/0x409/serialnumber
echo "Pi Zero" > strings/0x409/manufacturer
echo "DuckPi" > strings/0x409/product
mkdir configs/c.1
mkdir functions/hid.usb0
echo 1 > functions/hid.usb0/protocol
echo 1 > functions/hid.usb0/subclass
echo 8 > functions/hid.usb0/report_length
cp your_report_descriptor functions/hid.usb0/report_desc
ln -s functions/hid.usb0 configs/c.1/
echo "musb-hdrc.0.auto" > UDC
