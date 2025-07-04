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

  echo 0x1d6b | sudo tee idVendor >/dev/null
  echo 0x0104 | sudo tee idProduct >/dev/null

  mkdir -p strings/0x409
  echo "1234" | sudo tee strings/0x409/serialnumber >/dev/null
  echo "PiDuck" | sudo tee strings/0x409/manufacturer >/dev/null
  echo "DuckBuzz" | sudo tee strings/0x409/product >/dev/null

  mkdir -p functions/hid.usb0
  echo 1 | sudo tee functions/hid.usb0/protocol >/dev/null
  echo 1 | sudo tee functions/hid.usb0/subclass >/dev/null
  echo 8 | sudo tee functions/hid.usb0/report_length >/dev/null

  # basic keyboard descriptor
  cat << EOF | sudo tee functions/hid.usb0/report_desc >/dev/null
$(echo -ne '\x05\x01\x09\x06\xa1\x01\x05\x07\x19\xe0\x29\xe7\x15\x00\x25\x01\x75\x01\x95\x08\x81\x02\x95\x01\x75\x08\x81\x03\x95\x05\x75\x01\x05\x08\x19\x01\x29\x05\x91\x02\x95\x01\x75\x03\x91\x03\x95\x06\x75\x08\x15\x00\x25\x65\x05\x07\x19\x00\x29\x65\x81\x00\xc0')
EOF

  mkdir -p configs/c.1
  ln -s functions/hid.usb0 configs/c.1/

  sleep 1

  # Attach to UDC (USB Device Controller)
  udc=$(ls /sys/class/udc | head -n 1)
  if [ -z "$udc" ]; then
    echo "Error: No UDC device found!"
    exit 1
  fi
  echo "$udc" | sudo tee UDC >/dev/null

  echo "[✔] Gadget mode ENABLED"
}

### 3️⃣ Teardown gadget function
disable_gadget() {
  if [ -d /sys/kernel/config/usb_gadget/ducky ]; then
    cd /sys/kernel/config/usb_gadget/ducky
    echo "" | sudo tee UDC >/dev/null
    sudo rm configs/c.1/hid.usb0
    sudo rmdir functions/hid.usb0
    cd ..
    sudo rm -rf ducky
    sudo modprobe -r libcomposite
    echo "[✔] Gadget mode DISABLED"
  else
    echo "[i] Gadget not active, nothing to disable"
  fi
}

### Before enabling gadget, disable if already active
disable_gadget
enable_gadget

# Wait for /dev/hidg0 to appear
for i in {1..5}; do
  if [ -e /dev/hidg0 ]; then
    break
  fi
  sleep 1
done

if [ ! -e /dev/hidg0 ]; then
  echo "Error: /dev/hidg0 not found after enabling gadget."
  disable_gadget
  exit 1
fi

### 4️⃣ Execute payload
if command -v duckencode >/dev/null; then
  duckencode -i "$script" -o payload.bin
  sudo dd if=payload.bin of=/dev/hidg0 bs=8
else
  echo "[!] duckencode not found. Sending raw text..."
  sudo tee /dev/hidg0 < "$script" >/dev/null
fi

### Clean up
disable_gadget

echo "[✔] Payload executed and USB returned to normal!"
