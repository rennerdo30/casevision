# CaseVision

CaseVision transforms your computer case display into a dynamic video panel. Originally designed for the Jonsbo D41 case using a Raspberry Pi Zero 2 W, this project turns the case's built-in display into a controllable media screen.

## Features

- 🎥 Seamless video playback with hardware acceleration
- 🌐 Web-based control interface
- 📁 Local media file management (upload, delete, select)
- 🔗 URL-based media playback support
- ⚙️ Customizable VLC command-line parameters
- 🔄 Automatic rotation support (preconfigured for Jonsbo D41)
- 🔧 Systemd service integration for reliable operation

## Hardware Requirements

- (Jonsbo D41 Case)
- Raspberry Pi Zero 2 W (recommended, tested)

## Software Requirements

- Raspberry Pi OS Lite 32bit (recommended)
- Python 3.7+
- VLC media player
- Web browser for control interface

## Quick Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/casevision.git
cd casevision
```

2. Run the installation script:
```bash
chmod +x install.sh
./install.sh
```

The script will automatically:
- Install required packages
- Configure system settings
- Set up services
- Configure display rotation
- Create required directories
- Start the web interface

## Manual Installation

If you prefer to install manually, follow these steps:

1. Install required packages:
```bash
sudo apt-get update
sudo apt-get install vlc-plugin-base python3-flask python3-pip git
```

2. Create application directories:
```bash
sudo mkdir -p /opt/casevision/{templates,videos}
sudo chown -R $USER:$USER /opt/casevision
```

3. Copy application files:
```bash
cp app.py /opt/casevision/
cp templates/index.html /opt/casevision/templates/
```

4. Configure system services:
```bash
sudo cp systemd/casevision-control.service /etc/systemd/system/
sudo cp systemd/casevision-playback.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable casevision-control casevision-playback
sudo systemctl start casevision-control casevision-playback
```

## Usage

1. Access the web interface at `http://[raspberry-pi-ip]:8080`

2. Through the interface you can:
   - Upload new media files
   - Select and play existing media
   - Play media from URLs
   - Delete media files
   - Modify VLC command-line parameters

3. Media files are stored in `/opt/casevision/videos`

## Configuration

### Display Settings
The display is preconfigured for the Jonsbo D41 case (270-degree rotation). If needed, you can modify the rotation in `/boot/config.txt`:
```
display_rotate=3  # 3 = 270 degrees
```

### VLC Settings
Default VLC settings are optimized for the case display:
- Framebuffer output for direct rendering
- Hardware acceleration enabled
- Automatic video rotation
- Loop playback enabled

## Troubleshooting

1. If the web interface is not accessible:
   - Check if the service is running: `sudo systemctl status casevision-control`
   - Verify the firewall allows port 8080

2. If videos don't play:
   - Check service status: `sudo systemctl status casevision-playback`
   - Verify file permissions in `/opt/casevision/videos`
   - Check system logs: `journalctl -u casevision-playback`

3. Display issues:
   - Verify HDMI connection
   - Check rotation settings in `/boot/config.txt`
   - Ensure display resolution is set correctly

## Project Structure
```
/opt/casevision/
├── app.py              # Web application
├── templates/          # Web interface templates
├── videos/            # Media storage
└── vlc_config.json    # VLC configuration

/etc/systemd/system/
├── casevision-control.service
└── casevision-playback.service
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Released under the MIT License. See the LICENSE file for details.