#!/bin/bash

# CaseVision Installation Script
# For Jonsbo D41 & Raspberry Pi Zero 2 W

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print with color
print_status() {
    echo -e "${GREEN}[*]${NC} $1"
}

print_error() {
    echo -e "${RED}[!]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if NOT running as root
if [ "$EUID" -eq 0 ]; then 
    print_error "Please run as normal user, not as root"
    exit 1
fi

# Configuration
INSTALL_DIR="/opt/casevision"
CURRENT_USER=$USER
CURRENT_GROUP=$(id -gn)
MEDIA_DIR="/opt/casevision/videos"

print_status "Installing for user: $CURRENT_USER"
print_status "Using group: $CURRENT_GROUP"

# Check if sudo is available
if ! command -v sudo &> /dev/null; then
    print_error "sudo is not installed. Please install sudo first."
    exit 1
fi

# Test sudo access
if ! sudo -v; then
    print_error "Cannot obtain sudo privileges. Please make sure you have sudo rights."
    exit 1
fi

# Install required packages
print_status "Installing required packages..."
sudo apt-get update
sudo apt-get install -y vlc-plugin-base python3-flask python3-pip git

# Create installation directory
print_status "Creating installation directory..."
sudo mkdir -p $INSTALL_DIR
sudo mkdir -p $INSTALL_DIR/templates
mkdir -p $MEDIA_DIR

# Clone repository
print_status "Cloning CaseVision repository..."
TEMP_DIR=$(mktemp -d)
cd $TEMP_DIR
git clone https://github.com/rennerdo30/casevision.git
cd casevision

# Copy files maintaining directory structure
print_status "Copying files..."
ls -al
sudo cp -r opt/casevision/* $INSTALL_DIR/
sudo cp boot/firmware/config.txt /boot/firmware/config.txt
sudo cp boot/firmware/cmdline.txt /boot/firmware/cmdline.txt

# Set correct permissions
print_status "Setting permissions..."
sudo chown -R $CURRENT_USER:$CURRENT_GROUP $INSTALL_DIR
sudo chown -R $CURRENT_USER:$CURRENT_GROUP $MEDIA_DIR
sudo chmod 755 $INSTALL_DIR
sudo chmod 755 $MEDIA_DIR

# Create systemd services
print_status "Creating systemd services..."

# Create temporary service files and move them with sudo
cat > /tmp/casevision-control.service << EOL
[Unit]
Description=CaseVision Control Interface
After=network.target

[Service]
User=$CURRENT_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOL

cat > /tmp/casevision-playback.service << EOL
[Unit]
Description=CaseVision Display Service
After=multi-user.target

[Service]
Type=simple
User=$CURRENT_USER
Environment=DISPLAY=:0
ExecStart=/usr/bin/cvlc --no-video-title-show --loop --width=800 --height=1422 --no-osd --no-audio --drm-vout-window 800x1422+0+0
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOL

sudo mv /tmp/casevision-control.service /etc/systemd/system/
sudo mv /tmp/casevision-playback.service /etc/systemd/system/
sudo chmod 644 /etc/systemd/system/casevision-*.service

# Configure sudo permissions
print_status "Configuring sudo permissions..."
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: /bin/systemctl restart casevision-playback.service" | sudo tee /etc/sudoers.d/casevision
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: /bin/mv /tmp/video-playback.service /etc/systemd/system/casevision-playback.service" | sudo tee -a /etc/sudoers.d/casevision
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: /bin/systemctl daemon-reload" | sudo tee -a /etc/sudoers.d/casevision
sudo chmod 440 /etc/sudoers.d/casevision

# Enable and start services
print_status "Enabling and starting services..."
sudo systemctl daemon-reload
sudo systemctl enable casevision-control.service
sudo systemctl enable casevision-playback.service
sudo systemctl start casevision-control.service
sudo systemctl start casevision-playback.service

# Clean up
print_status "Cleaning up..."
rm -rf $TEMP_DIR

# Display completion message
IP_ADDRESS=$(hostname -I | cut -d' ' -f1)
print_status "Installation completed!"
echo -e "${GREEN}CaseVision has been installed successfully!${NC}"
echo -e "You can access the web interface at: ${YELLOW}http://$IP_ADDRESS:8080${NC}"
echo -e "Media directory is located at: ${YELLOW}$MEDIA_DIR${NC}"
echo -e "\nTo check service status:"
echo -e "  sudo systemctl status casevision-control"
echo -e "  sudo systemctl status casevision-playback"
echo -e "\nTo view logs:"
echo -e "  sudo journalctl -u casevision-control"
echo -e "  sudo journalctl -u casevision-playback"

print_warning "A reboot is recommended to apply all changes. Would you like to reboot now? (y/n)"
read reboot_response
if [[ "$reboot_response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
    sudo reboot
fi

exit 0