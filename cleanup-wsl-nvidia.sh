#!/usr/bin/env bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "Cleaning up NVIDIA libraries in WSL..."

# Check if NVIDIA libraries exist
if [ -d "/usr/lib/wsl/lib" ]; then
  echo "Checking NVIDIA libraries in /usr/lib/wsl/lib..."
  
  # Define core libraries to keep
  echo "Preserving only core CUDA libraries..."
  preserved_libs=(
    "libcudadebugger.so.1"
    "libcuda.so"
    "libcuda.so.1" 
    "libcuda.so.1.1"
  )

  # Remove everything except the core libraries
  echo "Removing all other libraries..."
  for file in /usr/lib/wsl/lib/*; do
    filename=$(basename "$file")
    should_preserve=false
    
    # Check if file should be preserved
    for lib in "${preserved_libs[@]}"; do
      if [ "$filename" = "$lib" ]; then
        should_preserve=true
        break
      fi
    done
    
    if [ "$should_preserve" = false ]; then
      echo "Removing $filename"
      rm -f "$file"
    fi
  done

  echo "Verifying remaining libraries:"
  ls -l /usr/lib/wsl/lib/
fi

# Remove any existing symlinks
echo "Removing symlinks..."
rm -f /usr/lib/libcuda.so /usr/lib/libnvidia-ml.so /usr/lib/libnvcuvid.so 2>/dev/null

echo "Cleanup complete! Please follow these steps:
1. Exit WSL
2. In Windows PowerShell run: wsl --shutdown
3. Uninstall NVIDIA drivers in Windows
4. Reboot Windows
5. Install latest NVIDIA drivers from nvidia.com
6. Reboot Windows again
7. Start WSL and run nvidia-smi to verify" 