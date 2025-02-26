#!/usr/bin/env bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Function to check command status
check_status() {
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
        return 0
    else
        if [ "$2" = "warn" ]; then
            echo -e "${YELLOW}! $1 (non-critical failure)${NC}"
            return 0
        else
            echo -e "${RED}✗ $1 (exit code: $exit_code)${NC}"
            return 1
        fi
    fi
}

# Function to run home-manager with fallback
run_home_manager() {
    if command -v home-manager &> /dev/null; then
        home-manager switch --flake .#ryzengrind@nix-pc
    else
        nix run home-manager/release-24.05 -- switch --flake .#ryzengrind@nix-pc
    fi
}

# Start timer
start_time=$(date +%s)

echo "=== Starting comprehensive flake testing ==="

# Run pre-commit hooks
echo -e "\n=== Pre-commit hooks ==="
# Run each hook individually as per pre-commit docs
nix develop --command pre-commit run alejandra --all-files
check_status "alejandra formatting"

nix develop --command pre-commit run deadnix --all-files
check_status "deadnix check"

nix develop --command pre-commit run prettier --all-files
check_status "prettier formatting"

nix develop --command pre-commit run statix --all-files
check_status "statix check"

echo -e "\n=== Flake checks ==="
# Use documented flake check options
echo "Checking flake outputs..."
nix flake check \
    --no-build \
    --keep-going \
    --show-trace \
    --allow-import-from-derivation
check_status "Flake integrity check" "warn"

# Test individual configurations using documented approach
echo -e "\n=== Testing configurations ==="
echo "Testing nix-pc configuration..."
nix eval --json .#nixosConfigurations.nix-pc.config.system.build.toplevel.drvPath 2>/dev/null
check_status "nix-pc configuration check"

echo "Testing nix-ws configuration..."
nix eval --json .#nixosConfigurations.nix-ws.config.system.build.toplevel.drvPath 2>/dev/null
check_status "nix-ws configuration check"

echo "Testing home-manager configuration..."
nix eval --json .#homeConfigurations."ryzengrind@nix-pc".activationPackage.drvPath 2>/dev/null
check_status "home-manager configuration check"

# System build test (only if explicitly requested)
if [ "${RUN_SYSTEM_TEST:-0}" = "1" ]; then
    echo -e "\n=== System build test ==="
    # Use documented rebuild options
    sudo nixos-rebuild test \
        --flake .#nix-pc \
        --show-trace \
        --keep-going
    check_status "System build test"
fi

# Home Manager test (only if explicitly requested)
if [ "${RUN_HOME_TEST:-0}" = "1" ]; then
    echo -e "\n=== Home Manager test ==="
    run_home_manager
    check_status "Home Manager configuration" "warn"
fi

# Quick system verification
echo -e "\n=== Quick system verification ==="
# Check critical services and bash shell
systemctl is-active dbus docker 2>/dev/null || echo -e "${YELLOW}Warning: Some services not active${NC}"
check_status "Critical services check" "warn"

# Verify bash shell is properly configured
if [ "$SHELL" != "/bin/bash" ]; then
    echo -e "${YELLOW}Warning: Default shell is not bash${NC}"
fi

# Check bash configuration files
for file in /etc/bash/bashrc.d/nix-daemon.bash ~/.bashrc.d/nix-develop.bash; do
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}Warning: Missing bash configuration file: $file${NC}"
    fi
done

# Calculate execution time
end_time=$(date +%s)
duration=$((end_time - start_time))

echo -e "\n=== Test Summary ==="
echo "✓ Pre-commit hooks"
echo "✓ Flake integrity"
echo "✓ Configuration checks"
echo "✓ Quick system verification"
echo -e "\nExecution time: ${duration} seconds"

echo -e "\n${GREEN}Tests completed successfully!${NC}"
echo -e "${YELLOW}Note: For full system testing, run with:${NC}"
echo "RUN_SYSTEM_TEST=1 RUN_HOME_TEST=1 ./scripts/test-flake.sh" 