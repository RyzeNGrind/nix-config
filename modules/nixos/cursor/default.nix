# Cursor IDE support module
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.cursor;
in {
  imports = [
    ../vscode
  ];

  options.services.cursor = {
    enable = mkEnableOption "Cursor IDE support";

    remote = {
      enable = mkEnableOption "Cursor remote development support";
      method = mkOption {
        type = types.enum ["nix-ld" "hybrid"];
        default = "hybrid";
        description = "Method to enable Cursor remote support (nix-ld or hybrid with node workaround)";
      };
      user = mkOption {
        type = types.str;
        default = "ryzengrind";
        description = "User account under which Cursor remote server runs.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      environment.systemPackages = with pkgs; [
        # Required for Cursor server setup
        jq
        wget
        curl
      ];

      # Copy server setup script
      # cp ${builtins.toString (pkgs.callPackage (builtins.getFlake "git+file://${builtins.getEnv "PWD"}").outPath + "/scripts/utilities/bin/server-env-setup.sh")} ~/.cursor-server/server-env-setup

      system.activationScripts.cursorSetup = ''
        mkdir -p ~/.cursor-server
        cp ${../../scripts/utilities/bin/server-env-setup.sh} ~/.cursor-server/server-env-setup
        chmod +x ~/.cursor-server/server-env-setup
      '';
    }

    (mkIf (cfg.remote.enable && (cfg.remote.method == "nix-ld" || cfg.remote.method == "hybrid")) {
      # Enable nix-ld for VSCode remote support
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          # Basic system libraries
          stdenv.cc.cc
          zlib
          openssl
          curl
          glib
          util-linux
          glibc

          # Additional libraries commonly needed
          icu
          libunwind
          libuuid
          libsecret
          libxkbcommon
          libxshmfence

          # X11 libraries
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXrandr
          xorg.libxcb

          # Audio libraries
          alsa-lib

          # GTK and related
          gtk3
          at-spi2-core
          at-spi2-atk
          dbus

          # Additional dependencies
          mesa
          nss
        ];
      };

      # Configure SSH to accept VSCode environment variables
      services.openssh.extraConfig = mkIf config.services.openssh.enable ''
        AcceptEnv VSCODE_WSL_EXT_LOCATION
        AcceptEnv VSCODE_SERVER_TAR
        AcceptEnv VSCODE_AGENT_FOLDER
        AcceptEnv VSCODE_INJECT_NODE_PATH
        AcceptEnv NODE_EXTRA_CA_CERTS
      '';

      # Set environment variables for VSCode remote
      environment.sessionVariables = {
        VSCODE_WSL_DEBUG_INFO = "true";
        NIXOS_OZONE_WL = "1"; # For Wayland support
      };
    })

    # Enable VSCode remote support for hybrid mode
    (mkIf (cfg.remote.enable && cfg.remote.method == "hybrid") {
      systemd.user.services.cursor-node-setup = {
        description = "Fix Cursor server Node.js binary paths";
        wantedBy = ["default.target"];
        path = [pkgs.bash];
        script = ''
          # Wait for the Cursor server directory to be created
          while [ ! -d "$HOME/.cursor-server/bin" ]; do
            sleep 1
          done

          # Create symlinks for each server binary
          for server_dir in "$HOME/.cursor-server/bin"/*; do
            if [ -d "$server_dir" ]; then
              ln -sf "${pkgs.nodejs_20}/bin/node" "$server_dir/node"
            fi
          done
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };
    })
  ]);
}
