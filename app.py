# CaseVision Controller - app.py
# A sleek display controller for your computer case
from flask import Flask, request, jsonify, send_from_directory, render_template
import os
import subprocess
import json
from werkzeug.utils import secure_filename
import getpass

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = '/opt/casevision/videos'
app.config['MAX_CONTENT_LENGTH'] = 1024 * 1024 * 1024  # 1GB max file size
CURRENT_USER = getpass.getuser()

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# Config file path
CONFIG_FILE = os.path.join('/opt/casevision', 'vlc_config.json')

def load_config():
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        return {
            'current_media': '',
            'command_line': f'/usr/bin/cvlc --no-video-title-show --loop --width=800 --height=1422 --no-osd --no-audio --drm-vout-window 800x1422+0+0'
        }

def save_config(config):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f)

def restart_vlc():
    subprocess.run(['sudo', 'systemctl', 'restart', 'casevision-playback.service'])

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/media/list')
def list_media():
    files = []
    for filename in os.listdir(app.config['UPLOAD_FOLDER']):
        if os.path.isfile(os.path.join(app.config['UPLOAD_FOLDER'], filename)):
            files.append(filename)
    return jsonify(files)

@app.route('/api/media/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    filename = secure_filename(file.filename)
    file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
    return jsonify({'message': 'File uploaded successfully'})

@app.route('/api/media/delete/<filename>', methods=['DELETE'])
def delete_file(filename):
    file_path = os.path.join(app.config['UPLOAD_FOLDER'], secure_filename(filename))
    if os.path.exists(file_path):
        os.remove(file_path)
        return jsonify({'message': 'File deleted successfully'})
    return jsonify({'error': 'File not found'}), 404

@app.route('/api/config', methods=['GET', 'PUT'])
def handle_config():
    if request.method == 'GET':
        return jsonify(load_config())
    
    config = request.json
    if "://" in config["current_media"]:
        config["current_media"] = config["current_media"]
    else:
        config["current_media"] = app.config['UPLOAD_FOLDER'] + "/" + config["current_media"]

    
    save_config(config)
    
    # Update systemd service file
    service_content = f'''[Unit]
Description=CaseVision Display Service
After=multi-user.target

[Service]
Type=simple
User={CURRENT_USER}
Environment=DISPLAY=:0
ExecStart={config['command_line']} {config['current_media']}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
'''
    
    with open('/tmp/casevision-playback.service', 'w') as f:
        f.write(service_content)
    
    # Move service file and restart
    subprocess.run(['sudo', 'mv', '/tmp/casevision-playback.service', '/etc/systemd/system/casevision-playback.service'])
    subprocess.run(['sudo', 'systemctl', 'daemon-reload'])
    restart_vlc()
    
    return jsonify({'message': 'Configuration updated'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)