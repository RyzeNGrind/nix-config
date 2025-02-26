#!/usr/bin/env bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Check if WSL NVIDIA directory exists
if [ ! -d "/usr/lib/wsl/lib" ]; then
  echo "Creating WSL NVIDIA directory..."
  mkdir -p /usr/lib/wsl/lib
fi

# Check if NVIDIA libraries are already present
if [ -f "/usr/lib/wsl/lib/libcuda.so.1" ] && \
   [ -f "/usr/lib/wsl/lib/libnvidia-ml.so.1" ] && \
   [ -f "/usr/lib/wsl/lib/libnvcuvid.so.1" ]; then
  echo "NVIDIA libraries already present in /usr/lib/wsl/lib"
else
  echo "Copying NVIDIA libraries from Windows..."
  # Check if source files exist
  if [ -d "/mnt/c/Windows/System32/lxss/lib" ]; then
    cp -f /mnt/c/Windows/System32/lxss/lib/* /usr/lib/wsl/lib/
  else
    echo "Error: Windows NVIDIA libraries not found in /mnt/c/Windows/System32/lxss/lib"
    exit 1
  fi
fi

# Set proper permissions
echo "Setting permissions..."
chmod 755 /usr/lib/wsl/lib/*
chown root:root /usr/lib/wsl/lib/*

# Create symlinks for commonly used libraries
echo "Creating symlinks..."
cd /usr/lib/wsl/lib || exit 1
for lib in libcuda.so libcuda.so.1 libnvidia-ml.so.1 libnvcuvid.so.1; do
  if [ -f "$lib" ]; then
    ln -sf "$lib" "${lib%.*}"
  fi
done

echo "Done! Please restart WSL for changes to take effect."
