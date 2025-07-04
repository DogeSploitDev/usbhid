#!/bin/bash
set -e

### CONFIG: your working directory
WORKDIR="$HOME/duckbuzz"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

### 1️⃣ Prompt and select script
echo "Available Duckyscripts in $WORKDIR:"
select script in *.txt *.duck; do
  [ -n "$script" ] && break
done
echo "[✔] Selected script: $script"

### 2️⃣ Setup gadget function
enable_gadget() {
  sudo modprobe libcomposite
  cd /sys/kernel/config/usb_gadget
  sudo mkdir -p ducky && cd ducky
  echo 0x1d6b > idVendor
  echo 0x0104 > idProduct
  mkdir -p strings/0x409
  echo "1234" > strings/0x409/serialnumber
  echo "PiDuck" > strings/0x409/manufacturer
  echo "DuckBuzz" > strings/0x409/product
  mkdir -p functions/hid.usb0
  echo 1 > functions/hid.usb0/protocol
  echo 1 > functions/hid.usb0/subclass
  echo 8 > functions/hid.usb0/report_length
  # basic keyboard descriptor
  cat << EOF | sudo tee functions/hid.usb0/report_desc >/dev/null
$(echo -ne '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x03\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x03\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0')
EOF
  mkdir -p configs/c.1
  ln -s functions/hid.usb0 configs/c.1/
  sleep 1
  echo "$(ls /sys/class/udc)" | sudo tee UDC >/dev/null
  echo "[✔] Gadget mode ENABLED"
}

### 3️⃣ Teardown gadget function
disable_gadget() {
  cd /sys/kernel/config/usb_gadget/ducky
  echo "" | sudo tee UDC >/dev/null
  sudo rm configs/c.1/hid.usb0
  sudo rmdir functions/hid.usb0
  cd ..
  sudo rm -rf ducky
  sudo modprobe -r libcomposite
  echo "[✔] Gadget mode DISABLED"
}

### 4️⃣ Execute payload
enable_gadget

# compile with duckencode if available
if command -v duckencode >/dev/null; then
  duckencode -i "$script" -o payload.bin
  sudo cat payload.bin > /dev/hidg0
else
  echo "[!] duckencode not found. Sending raw text..."
  sudo cat "$script" | sudo tee /dev/hidg0 >/dev/null
fi

disable_gadget

echo "[✔] Payload executed and USB returned to normal!"
