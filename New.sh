# Load necessary kernel modules
sudo modprobe dwc2
sudo modprobe libcomposite

# Go to configfs USB gadget directory
cd /sys/kernel/config/usb_gadget

# Remove old gadget if any
sudo rm -rf ducky

# Create new gadget folder
sudo mkdir ducky
cd ducky

# Set vendor/product IDs
echo 0x1d6b | sudo tee idVendor
echo 0x0104 | sudo tee idProduct

# Create English strings
sudo mkdir -p strings/0x409
echo "123456789" | sudo tee strings/0x409/serialnumber
echo "TestManufacturer" | sudo tee strings/0x409/manufacturer
echo "TestProduct" | sudo tee strings/0x409/product

# Create configuration
sudo mkdir -p configs/c.1
echo 120 | sudo tee configs/c.1/MaxPower

# Create HID function
sudo mkdir -p functions/hid.usb0
echo 1 | sudo tee functions/hid.usb0/protocol
echo 1 | sudo tee functions/hid.usb0/subclass
echo 8 | sudo tee functions/hid.usb0/report_length

# Set report descriptor (keyboard)
echo -ne '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x03\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x03\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0' | sudo tee functions/hid.usb0/report_desc

# Link HID function to config
sudo ln -s functions/hid.usb0 configs/c.1/

# Find UDC device name
UDC=$(ls /sys/class/udc | head -n 1)
echo "Using UDC device: $UDC"

# Bind gadget to UDC
echo $UDC | sudo tee UDC
