# Host-specific home configuration for daimyo00
{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    ../../modules/home-manager/wsl.nix  # Import our WSL module
  ];

  # Basic home-manager settings
  home = {
    username = "ryzengrind";
    homeDirectory = "/home/ryzengrind";
    stateVersion = "24.05";
    
    # Host-specific packages
    packages = with pkgs; [
      # Development tools
      git
      gh
      direnv
      nix-direnv
      pre-commit
      
      # System tools
      htop
      btop
      iotop
      
      # Network tools
      curl
      wget
      dig
      whois
      
      # Terminal utilities
      tmux
      fzf
      ripgrep
      fd
      jq
      yq

      # IDE utilities
      pre-commit
      _1password-gui
      nixfmt-classic
      nix-ld
      
      # VSCodium cursor server setup
      (writeTextFile {
        name = "vscodium-cursor-server";
        destination = "/bin/vscodium-cursor-server";
        executable = true;
        text = ''
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
          unset fix_download
        '';
      })
      
      # Update 1Password package configuration
      (pkgs.writeShellScriptBin "1password" ''
        nohup ${pkgs._1password-gui}/bin/1password --silent > /dev/null 2>&1 &
      '')
    ];
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  # Host-specific program configurations
  programs = {
    git = {
      enable = true;
      userName = "ryzengrind";
      userEmail = "ryzengrind@daimyo00.local";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
      };
      package = pkgs.git;
    };

    bash = {
      enable = true;
      enableCompletion = true;
      shellAliases = {
        ll = "ls -la";
        ".." = "cd ..";
        "..." = "cd ../..";
        rebuild = "sudo nixos-rebuild switch --flake .#daimyo00";
        update = "nix flake update";
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    vim = {
      enable = true;
      extraConfig = ''
        set number
        set relativenumber
        set expandtab
        set tabstop=2
        set shiftwidth=2
        syntax on
      '';
    };

    vscode = {
      enable = true;
      package = pkgs.vscodium;  # Switch to VSCodium
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      
      extensions = with pkgs.vscode-extensions; [
        # Nix support
        bbenoist.nix
        jnoortheen.nix-ide
        brettm12345.nixfmt-vscode
        
        # Git integration
        eamodio.gitlens
        mhutchie.git-graph
        
        # Remote development
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-wsl
        
        # General development
        ms-azuretools.vscode-docker
        redhat.vscode-yaml
        yzhang.markdown-all-in-one
        
        # Theme and UI
        pkief.material-icon-theme
        
        # Editor enhancements
        editorconfig.editorconfig
        esbenp.prettier-vscode
        
        # AI assistance
        github.copilot
      ];
      
      userSettings = {
        "editor.fontFamily" = "'FiraCode Nerd Font', 'Droid Sans Mono', 'monospace'";
        "editor.fontSize" = 14;
        "editor.formatOnSave" = true;
        "editor.rulers" = [ 80 120 ];
        "editor.renderWhitespace" = "boundary";
        "editor.suggestSelection" = "first";
        "editor.bracketPairColorization.enabled" = true;
        
        "workbench.colorTheme" = "Default Dark Modern";
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.startupEditor" = "none";
        
        "files.autoSave" = "onFocusChange";
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;
        
        "terminal.integrated.fontFamily" = "'FiraCode Nerd Font'";
        "terminal.integrated.fontSize" = 14;
        
        "git.enableSmartCommit" = true;
        "git.autofetch" = true;
        
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        
        "[nix]" = {
          "editor.tabSize" = 2;
          "editor.formatOnSave" = true;
        };

        # VSCodium-specific settings for cursor server
        "remote.SSH.remotePlatform" = {
          "localhost" = "linux";
        };
        "remote.SSH.useLocalServer" = true;
        "remote.SSH.enableDynamicForwarding" = true;
        "remote.SSH.enableRemoteCommand" = true;
      };
    };
  };

  # Pre-commit configuration at home-manager level
  pre-commit = {
    enable = true;
    hooks = {
      nixpkgs-fmt.enable = true;
      prettier.enable = true;
      black.enable = true;
    };
  };

  # Enable fonts in home-manager
  fonts.fontconfig.enable = true;
} 