# CaseVision

CaseVision transforms your computer case display into a dynamic video panel. Originally designed for the Jonsbo D41 case using a Raspberry Pi Zero 2 W, this project turns the case's built-in display into a controllable media screen. It provides a web-based control interface to manage media playback on a Raspberry Pi-powered display, perfect for showing animations, information, or any visual content on your computer case.

## Features

- 🎥 Seamless video playback with hardware acceleration
- 🌐 Web-based control interface
- 📁 Local media file management (upload, delete, select)
- 🔗 URL-based media playback support
- ⚙️ Customizable VLC command-line parameters
- 🔄 Automatic rotation support for display orientation
- 🔧 Systemd service integration for reliable operation

## Hardware Requirements

- Jonsbo D41 Case
- Raspberry Pi Zero 2 W (recommended, tested)
  - Other Raspberry Pi models may work but are not tested
- Raspberry Pi OS
- Python 3.7+
- VLC media player
- Web browser for control interface

## Installation

1. Install required packages:
```bash
sudo apt-get update
sudo apt-get install vlc-plugin-base python3-flask python3-pip
```

2. Create application directory:
```bash
mkdir -p ~/casevision/templates
cd ~/casevision
```

3. Copy the application files:
- Save `app.py` to `~/casevision/`
- Save `templates/index.html` to `~/casevision/templates/`

4. Set up systemd services:

Create the control service:
```bash
sudo nano /etc/systemd/system/casevision-control.service
```
```ini
[Unit]
Description=CaseVision Control Interface
After=network.target

[Service]
User=pi
WorkingDirectory=/home/pi/casevision
ExecStart=/usr/bin/python3 app.py
Restart=always

[Install]
WantedBy=multi-user.target
```

Create the playback service:
```bash
sudo nano /etc/systemd/system/casevision-playback.service
```
```ini
[Unit]
Description=CaseVision Display Service
After=multi-user.target

[Service]
Type=simple
User=pi
Environment=DISPLAY=:0
ExecStart=/usr/bin/cvlc --no-audio --fullscreen --loop --no-osd --framebuffer-vdev=/dev/fb0 --video-filter="transform{type=270}"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

5. Configure sudo permissions:
```bash
sudo visudo -f /etc/sudoers.d/casevision
```
Add:
```
pi ALL=(ALL) NOPASSWD: /bin/systemctl restart casevision-playback.service, /bin/mv /tmp/video-playback.service /etc/systemd/system/casevision-playback.service, /bin/systemctl daemon-reload
```

6. Enable and start services:
```bash
sudo systemctl enable casevision-control.service
sudo systemctl enable casevision-playback.service
sudo systemctl start casevision-control.service
sudo systemctl start casevision-playback.service
```

## Usage

1. Access the web interface at `http://[raspberry-pi-ip]:8080`

2. Through the interface you can:
   - Upload new media files
   - Select and play existing media
   - Play media from URLs
   - Delete media files
   - Modify VLC command-line parameters

3. Default media directory: `/home/rennerdo30/Videos`

## Display Rotation

The default configuration rotates the display 270 degrees counterclockwise. To modify this:

1. Edit boot config:
```bash
sudo nano /boot/config.txt
```

2. Add or modify:
```
display_rotate=3  # 3 = 270 degrees
```

## Troubleshooting

1. If the web interface is not accessible:
   - Check if the service is running: `sudo systemctl status casevision-control`
   - Verify the firewall allows port 8080

2. If videos don't play:
   - Check VLC service status: `sudo systemctl status casevision-playback`
   - Verify file permissions in the media directory
   - Check system logs: `journalctl -u casevision-playback`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

Released under the MIT License. See the LICENSE file for details.