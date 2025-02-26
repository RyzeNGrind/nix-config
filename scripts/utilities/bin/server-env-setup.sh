#!/usr/bin/env bash

export VSCODE_WSL_DEBUG_INFO=true

fix_download() {
    case "$QUALITY" in
        stable)
            local app_name='cursor';;
        *)
            echo "unknown quality: $QUALITY" 1>&2
            return 1;;
    esac
    local ps='/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe'
    local cmd="(Get-Command $app_name).Path | Split-Path | Split-Path"
    local install_dir=$(wslpath -u "$($ps -nop -c "$cmd | Write-Host -NoNewLine")")

    local product_json="$install_dir/product.json"
    local release=$(jq -r .cursorServerRelease "$product_json")
    local vscodium_release=$(jq -r .release "$product_json")
    local version=$(jq -r .version "$product_json")
    local vscodium_version=$(jq -r .vscodeVersion "$product_json")
    case $version in null.*)
        version=$(jq -r .version "$product_json");;
    esac
    case $vscodium_version in null.*)
        vscodium_version=$(jq -r .version "$product_json");;
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
    local url="https://cursor.blob.core.windows.net/remote-releases/${version}-${release}/vscode-reh-linux-${platform}.tar.gz"
    local fallback_url="https://github.com/VSCodium/vscodium/releases/download/${vscodium_version}.${vscodium_release}/vscodium-reh-linux-${platform}-${vscodium_version}.${vscodium_release}.tar.gz"

    # Attempt to download from the initial URL
    export VSCODE_SERVER_TAR=$(curl -fLOJ "$url" --output-dir /tmp -w '%{filename_effective}')
    if [ $? -ne 0 ]; then
        # If the download fails, attempt to download from the fallback URL
        export VSCODE_SERVER_TAR=$(curl -fLOJ "$fallback_url" --output-dir /tmp -w '/tmp/%{filename_effective}')
    fi

    export REMOVE_SERVER_TAR_FILE=true
}
[ "$VSCODE_WSL_DEBUG_INFO" = true ] && set -x
if [ ! -d "$HOME/$DATAFOLDER/bin/$COMMIT" ]; then
    if [ ! -d "$HOME/$DATAFOLDER/bin_commit" ]; then
        set -e
        fix_download
        set +e
    fi
fi
unset fix_download 