#!/usr/bin/env bash

# uncomment the following line to enable debugging
#export VSCODE_WSL_DEBUG_INFO=true

INIT_FILE="$HOME/.vscodium-server/initialized"

fix_download() {
    case "$QUALITY" in
        stable)
            local repo_name='vscodium'
            local app_name='codium';;
        insider)
            local repo_name='vscodium-insiders'
            local app_name='codium-insiders';;
        *)
            echo "unknown quality: $QUALITY" 1>&2
            return 1;;
    esac
    local ps='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
    local cmd="(Get-Command $app_name).Path | Split-Path | Split-Path"
    local install_dir=$(wslpath -u "$($ps -nop -c "$cmd | Write-Host -NoNewLine")")
    local product_json="$install_dir/resources/app/product.json"
    local release=$(jq -r .release "$product_json")
    local version=$(jq -r .vscodeVersion "$product_json" | sed "s#\(-$QUALITY\)\?\$#.$release&#")
    case $version in null.*)
        version=$(jq -r .version "$product_json" | sed "s#\(-$QUALITY\)\?\$#.$release&#");;
    esac
    local arch=$(uname -m)
    case $arch in
        x86_64)
            local platform='x64';;
        armv7l | armv8l)
            local platform='armhf';;
        arm64 | aarch64)
            local platform='arm64';;
        *)
            echo "unknown machine: $arch" 1>&2
            return 1;;
    esac
    local url="https://github.com/VSCodium/$repo_name/releases/download/$version/vscodium-reh-linux-$platform-$version.tar.gz"
    export VSCODE_SERVER_TAR=$(curl -fLOJ "$url" --output-dir /tmp -w '/tmp/%{filename_effective}')
    export REMOVE_SERVER_TAR_FILE=true
}

[ "$VSCODE_WSL_DEBUG_INFO" = true ] && set -x

# Check if this is first time initialization
if [ ! -f "$INIT_FILE" ]; then
    if [ ! -d "$HOME/$DATAFOLDER/bin/$COMMIT" ]; then
        if [ ! -d "$HOME/$DATAFOLDER/bin_commit" ]; then
            set -e
            fix_download
            set +e
            # Create initialization flag file
            touch "$INIT_FILE"
            echo "cursor-server has been setup for remote SSH and WSL."
        fi
    fi
fi 