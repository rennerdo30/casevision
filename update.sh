#!/bin/bash

# CaseVision Update Script

git config --global --add safe.directory /opt/casevision
git pull https://github.com/rennerdo30/casevision.git

sudo systemctl daemon-reload
sudo systemctl restart casevision-playback
sudo systemctl restart casevision-control
