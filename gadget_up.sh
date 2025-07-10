echo "dtoverlay=dwc2,dr_mode=peripheral" | sudo tee -a /boot/config.txt
echo -e "dwc2\nlibcomposite" | sudo tee -a /etc/modules
