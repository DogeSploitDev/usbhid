#!/bin/bash
set -e

### 1. Pre-flight: enable modules and clean previous gadget
echo "dtoverlay=dwc2" | grep -qxFf - /boot/config.txt || echo "dtoverlay=dwc2" | sudo tee -a /boot/config.txt
echo -e "dwc2\nlibcomposite" | sudo tee /etc/modules

# Clean old gadget
cd /sys/kernel/config/usb_gadget
if [ -d duckbuzz ]; then
  cd duckbuzz
  echo "" | sudo tee UDC || true
  sudo rm configs/c.1/hid.usb0 2>/dev/null || true
  sudo rmdir functions/hid.usb0 2>/dev/null || true
  cd ..
  sudo rm -rf duckbuzz
fi

### 2. Create gadget
cd /sys/kernel/config/usb_gadget
sudo mkdir duckbuzz && cd duckbuzz
sudo bash -c '
  echo 0x1d6b > idVendor
  echo 0x0104 > idProduct
  mkdir -p strings/0x409
  echo "1234" > strings/0x409/serialnumber
  echo "KaliPi" > strings/0x409/manufacturer
  echo "DuckBuzz" > strings/0x409/product

  mkdir -p functions/hid.usb0
  echo 1 > functions/hid.usb0/protocol
  echo 1 > functions/hid.usb0/subclass
  echo 8 > functions/hid.usb0/report_length

  # Standard keyboard report descriptor
  echo -ne "\\x05\\x01\\x09\\x06\\xa1\\x01\\x05\\x07\\x19\\xe0\\x29\\xe7\\x15\\x00\\x25\\x01\\x75\\x01\\x95\\x08\\x81\\x02\\x95\\x01\\x75\\x08\\x81\\x03\\x95\\x05\\x75\\x01\\x05\\x08\\x19\\x01\\x29\\x05\\x91\\x02\\x95\\x01\\x75\\x03\\x91\\x03\\x95\\x06\\x75\\x08\\x15\\x00\\x25\\x65\\x05\\x07\\x19\\x00\\x29\\x65\\x81\\x00\\xc0" \
    > functions/hid.usb0/report_desc

  mkdir -p configs/c.1
  ln -s functions/hid.usb0 configs/c.1/
'

# Give hardware time and bind
sleep 2
echo "$(ls /sys/class/udc)" | sudo tee UDC

echo "[✔] Gadget up! /dev/hidg0 ready."

### 3. Choose and run Duckyscript payload
echo "Pick a Duckyscript file (*.txt or *.duck):"
select script in *.txt *.duck; do
  [ -n "$script" ] && break
done

echo "[✔] Selected: $script"

# Compile using DuckToolkit if installed, otherwise remark
if command -v duckencode >/dev/null 2>&1; then
  duckencode -i "$script" -o payload.bin
  bin2h /dev/zero < payload.bin > duck.bin
  cat payload.bin > /dev/hidg0
  echo "[✔] Payload injected!"
else
  echo "[!] duckencode not found. Install it or place compiled .bin in same folder."
  cat "$script" | ./duckpi.sh  # If you have the DuckBerry script
fi
