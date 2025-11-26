#!/usr/bin/env bash
set -e

echo "=== Checking if system supports apt ==="
if ! command -v apt >/dev/null 2>&1; then
  echo "This script works only on Ubuntu/Debian systems."
  exit 1
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo "=== Updating package list ==="
sudo apt update -y

########################################
# Docker
########################################
echo "=== Installing Docker ==="

if command_exists docker; then
  echo "Docker is already installed: $(docker --version)"
else
  sudo apt install -y docker.io
  echo "Docker installed: $(docker --version)"
  sudo usermod -aG docker "$USER" || true
  echo "⚠️ Please log out and log back in to use Docker without sudo."
fi

########################################
# Docker Compose
########################################
echo "=== Installing Docker Compose ==="

if command_exists docker-compose; then
  echo "Docker Compose is already installed: $(docker-compose --version)"
else
  sudo apt install -y docker-compose
  echo "Docker Compose installed: $(docker-compose --version)"
fi

########################################
# Python 3 + pip
########################################
echo "=== Checking Python 3 ==="

if command_exists python3; then
  PY_VER=$(python3 -V | awk '{print $2}')
  echo "Python detected: $PY_VER"
else
  echo "Python not found. Installing..."
  sudo apt install -y python3 python3-venv python3-full
fi

echo "=== Installing python3-venv and pip ==="
sudo apt install -y python3-venv python3-pip python3-full

########################################
# Django in Virtual Environment
########################################
echo "=== Setting up Django inside a virtual environment ==="

# Create venv if missing
if [ ! -d "./venv" ]; then
  echo "Creating virtual environment at ./venv"
  python3 -m venv venv
fi

echo "Activating virtual environment..."
source venv/bin/activate

echo "Upgrading pip inside the virtual environment..."
pip install --upgrade pip

if command -v django-admin >/dev/null 2>&1; then
  echo "Django is already installed: $(django-admin --version)"
else
  echo "Installing Django..."
  pip install django
  echo "Django installed: $(django-admin --version)"
fi

echo "Deactivating virtual environment..."
deactivate

echo "=== Django installed inside ./venv ==="
echo "=== All development tools installed successfully! ==="
