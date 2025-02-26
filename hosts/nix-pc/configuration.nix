# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').
# Surface Book 3 WSL Configuration
{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    # Import WSL base configuration
    inputs.nixos-wsl.nixosModules.wsl
  ];

  # Set the system state version
  system.stateVersion = "24.05"; # Did you read the comment?

  # Enable WSL features
  wsl = {
    enable = true;
    defaultUser = "ryzengrind";
    docker-desktop.enable = true;
    nativeSystemd = true;
    startMenuLaunchers = true;
    wslConf = {
      automount = {
        enabled = true;
        options = "metadata,umask=22,fmask=11,uid=1000,gid=100";
        mountFsTab = false;
        root = "/mnt";
      };
      network = {
        generateHosts = true;
        generateResolvConf = true;
        hostname = "nix-pc";
      };
      interop = {
        appendWindowsPath = false;
      };
    };
    extraBin = with pkgs; [
      # Core utilities
      { src = "${coreutils}/bin/env"; }
      { src = "${coreutils}/bin/uname"; }
      { src = "${coreutils}/bin/mktemp"; }
      { src = "${coreutils}/bin/dirname"; }
      { src = "${coreutils}/bin/basename"; }
      { src = "${coreutils}/bin/readlink"; }
      { src = "${coreutils}/bin/realpath"; }
      { src = "${coreutils}/bin/cat"; }
      { src = "${coreutils}/bin/sed"; }
      # Shell and tools
      { src = "${bash}/bin/bash"; }
      { src = "${starship}/bin/starship"; }
      { src = "${zoxide}/bin/zoxide"; }
      { src = "${direnv}/bin/direnv"; }
      { src = "${git}/bin/git"; }
      # System tools
      { src = "${sudo}/bin/sudo"; }
    ];
  };

  # Security configuration for WSL
  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
      extraConfig = ''
        Defaults env_keep += "NIXOS_EXTRA_ENVIRONMENT"
        Defaults env_keep += "NIX_PATH"
        Defaults env_keep += "NIX_PROFILES"
        Defaults env_keep += "NIX_SSL_CERT_FILE"
        Defaults env_keep += "NIX_USER_PROFILE_DIR"
      '';
      extraRules = [
        {
          groups = ["wheel"];
          commands = [
            {
              command = "ALL";
              options = ["NOPASSWD"];
            }
          ];
        }
      ];
    };
    wrappers = {
      sudo = {
        source = "${pkgs.sudo.out}/bin/sudo";
        owner = "root";
        group = "root";
        setuid = true;
      };
    };
  };

  # System activation script to fix permissions and links
  system.activationScripts = {
    wslSetup = lib.stringAfter ["users" "groups"] ''
      # Create required directories with proper permissions
      mkdir -p /nix/var/nix/profiles/default/bin
      mkdir -p /nix/var/nix/profiles/default/etc/profile.d
      mkdir -p /run/current-system/sw/bin
      mkdir -p /run/wrappers/bin
      mkdir -p /usr/bin
      mkdir -p /bin
      mkdir -p /usr/local/bin
      mkdir -p /etc/bash/bashrc.d
      mkdir -p /home/ryzengrind/.config/bash
      mkdir -p /nix/store

      # Find Git and its dependencies
      GIT_STORE_PATH=$(find /nix/store -name git -type f -executable | head -n 1)
      GIT_DIR=$(dirname "$GIT_STORE_PATH")
      
      if [ -n "$GIT_STORE_PATH" ]; then
        # Link Git and its core commands
        ln -sf "$GIT_STORE_PATH" /usr/bin/git
        ln -sf "$GIT_DIR/git-remote" /usr/bin/git-remote
        ln -sf "$GIT_DIR/git-upload-pack" /usr/bin/git-upload-pack
        ln -sf "$GIT_DIR/git-receive-pack" /usr/bin/git-receive-pack
        ln -sf "$GIT_DIR/git-shell" /usr/bin/git-shell
        
        # Also link to nix profile
        ln -sf "$GIT_STORE_PATH" /nix/var/nix/profiles/default/bin/git
        ln -sf "$GIT_DIR/git-remote" /nix/var/nix/profiles/default/bin/git-remote
        ln -sf "$GIT_DIR/git-upload-pack" /nix/var/nix/profiles/default/bin/git-upload-pack
        ln -sf "$GIT_DIR/git-receive-pack" /nix/var/nix/profiles/default/bin/git-receive-pack
        ln -sf "$GIT_DIR/git-shell" /nix/var/nix/profiles/default/bin/git-shell
      fi

      # Ensure proper permissions for Nix directories
      chmod 755 /nix
      chmod 755 /nix/var
      chmod 755 /nix/var/nix
      chmod 755 /nix/var/nix/profiles
      chmod 755 /nix/var/nix/profiles/default
      chmod 755 /nix/var/nix/profiles/default/bin
      chmod 755 /nix/store

      # Find the actual nix package in the store
      NIX_STORE_PATH=$(readlink -f /run/current-system/sw)
      NIX_BIN_PATH=$(find $NIX_STORE_PATH -name nix -type f -executable | head -n 1)
      NIX_DIR=$(dirname "$NIX_BIN_PATH")

      if [ -n "$NIX_BIN_PATH" ]; then
        # Create symlinks for Nix commands using the found path
        ln -sf "$NIX_BIN_PATH" /usr/bin/nix
        ln -sf "$NIX_DIR/nixos-rebuild" /usr/bin/nixos-rebuild
        ln -sf "$NIX_DIR/nix-env" /usr/bin/nix-env
        ln -sf "$NIX_DIR/nix-shell" /usr/bin/nix-shell
        ln -sf "$NIX_DIR/nix-store" /usr/bin/nix-store
        ln -sf "$NIX_DIR/nix-channel" /usr/bin/nix-channel

        ln -sf "$NIX_BIN_PATH" /nix/var/nix/profiles/default/bin/nix
        ln -sf "$NIX_DIR/nixos-rebuild" /nix/var/nix/profiles/default/bin/nixos-rebuild
        ln -sf "$NIX_DIR/nix-env" /nix/var/nix/profiles/default/bin/nix-env
        ln -sf "$NIX_DIR/nix-shell" /nix/var/nix/profiles/default/bin/nix-shell
        ln -sf "$NIX_DIR/nix-store" /nix/var/nix/profiles/default/bin/nix-store
        ln -sf "$NIX_DIR/nix-channel" /nix/var/nix/profiles/default/bin/nix-channel
      fi

      # Create symlinks for essential commands with absolute paths
      CORE_PATH=$(find /nix/store -name coreutils -type d | head -n 1)
      if [ -n "$CORE_PATH" ]; then
        ln -sf "$CORE_PATH/bin/uname" /usr/bin/uname
        ln -sf "$CORE_PATH/bin/dirname" /usr/bin/dirname
        ln -sf "$CORE_PATH/bin/basename" /usr/bin/basename
        ln -sf "$CORE_PATH/bin/readlink" /usr/bin/readlink
        ln -sf "$CORE_PATH/bin/realpath" /usr/bin/realpath
        ln -sf "$CORE_PATH/bin/env" /usr/bin/env
        ln -sf "$CORE_PATH/bin/mktemp" /usr/bin/mktemp
        ln -sf "$CORE_PATH/bin/kill" /usr/bin/kill
      fi

      # Link sudo with proper permissions
      SUDO_PATH=$(find /nix/store -name sudo -type f -executable | head -n 1)
      if [ -n "$SUDO_PATH" ]; then
        ln -sf "$SUDO_PATH" /usr/bin/sudo
        ln -sf "$SUDO_PATH" /run/wrappers/bin/sudo
        chmod u+s /run/wrappers/bin/sudo
      fi

      # Set up bash shell symlinks with absolute paths
      BASH_PATH=$(find /nix/store -name bash -type f -executable | head -n 1)
      if [ -n "$BASH_PATH" ]; then
        ln -sf "$BASH_PATH" /bin/bash
      fi

      # Ensure proper permissions for user directories
      chown -R ryzengrind:users /home/ryzengrind/.config/bash
      chmod 700 /home/ryzengrind/.config/bash
    '';
  };

  # Enable core features
  core = {
    enable = true;
    system = {
      enable = true;
      kernel = {
        enable = true;
        packages = pkgs.linuxPackages;
        modules = [];
      };
      shell = {
        enable = true;
        bash = {
          enable = true;
          default = true;
        };
      };
      network = {
        enable = true;
        hostName = "nix-pc";
      };
    };
  };

  # Enable development features
  core.features = {
    development = {
      enable = true;
      tools = {
        enable = true;
        containers = {
          enable = true;
          docker.enable = true;
        };
      };
      ide = {
        vscode.enable = true;
        cursor.enable = true;
      };
    };
  };

  # Host-specific networking
  networking = {
    hostName = "nix-pc";
    networkmanager.enable = true;
  };

  # Nix configuration
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
        "repl-flake"
        "recursive-nix"
        "fetch-closure"
        "dynamic-derivations"
        "daemon-trust-override"
        "cgroups"
        "ca-derivations"
        "auto-allocate-uids"
        "impure-derivations"
      ];
      trusted-users = ["root" "@wheel"];
      auto-optimise-store = true;
      warn-dirty = true; # Enable dirty git tree warnings during development
      accept-flake-config = true;
      system-features = [
        "big-parallel"
        "kvm"
        "nixos-test"
        "benchmark"
        "ca-derivations"
      ];
      max-jobs = "auto";
      cores = 0;
      keep-outputs = true;
      keep-derivations = true;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
      fallback = true
    '';
  };

  # Systemd configuration for WSL
  systemd = {
    enableUnifiedCgroupHierarchy = false;
    services = {
      NetworkManager-wait-online.enable = false;
      dbus = {
        wantedBy = ["multi-user.target"];
        requires = ["dbus.socket"];
      };
      "systemd-tmpfiles-setup" = {
        wantedBy = ["basic.target"];
        before = ["basic.target"];
      };
    };
  };

  # Surface Book 3 specific hardware settings
  hardware = {
    # Add any specific hardware settings here
    opengl.enable = true;
    pulseaudio.enable = true;
  };

  # Host-specific packages and dconf dependencies
  environment = {
    binsh = "${pkgs.bash}/bin/bash";
    shells = [ "${pkgs.bash}/bin/bash" ];
    variables = {
      SHELL = "${pkgs.bash}/bin/bash";
      PATH = lib.mkForce "/nix/store/*/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/run/wrappers/bin:/usr/local/bin:/usr/bin:/bin";
      NIX_PATH = lib.mkForce "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:nixos-config=/etc/nixos/configuration.nix:/nix/var/nix/profiles/per-user/root/channels";
      NIX_PROFILES = "/nix/var/nix/profiles/default /run/current-system/sw";
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      NIX_STORE = "/nix/store";
    };

    systemPackages = with pkgs; [
      # Core utilities
      coreutils
      findutils
      gnugrep
      gnused
      gnutar
      gzip
      xz
      gawk
      util-linux

      # Nix tools
      nix
      nixos-rebuild
      nix-index
      nix-prefetch-scripts

      # Shell tools
      bash
      starship
      zoxide
      direnv
      git

      # Additional tools
      eza
      bat
      fd
      ripgrep
      jq
      yq

      # Dconf and related tools
      dconf
      gnome.dconf-editor

      # Shell integration
      any-nix-shell
      fzf

      # Add nix-env.bash to system packages
      (pkgs.writeTextFile {
        name = "nix-daemon.bash";
        destination = "/etc/bash/bashrc.d/nix-daemon.bash";
        text = ''
          # Set up the Nix environment
          export NIX_PROFILES="/nix/var/nix/profiles/default /run/current-system/sw $HOME/.nix-profile"
          export NIX_PATH="nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos:$HOME/.nix-defexpr/channels"
          export NIX_SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"

          # Add Nix paths to PATH
          for p in $NIX_PROFILES; do
            if [ -d "$p/bin" ]; then
              case ":$PATH:" in
                *":$p/bin:"*) ;;
                *) export PATH="$p/bin:$PATH" ;;
              esac
            fi
          done

          # Initialize starship prompt if available
          if command -v starship &>/dev/null; then
            eval "$(starship init bash)"
          fi

          # Initialize direnv if available
          if command -v direnv &>/dev/null; then
            eval "$(direnv hook bash)"
          fi

          # Initialize zoxide if available
          if command -v zoxide &>/dev/null; then
            eval "$(zoxide init bash)"
          fi
        '';
      })
    ];

    # Link core tools to standard locations
    extraOutputsToInstall = ["dev" "info" "man"];
    pathsToLink = [
      "/bin"
      "/share/bash-completion"
    ];
  };

  # Enable dconf and D-Bus (required for Home Manager)
  programs.dconf.enable = true;

  # Configure D-Bus for WSL
  services.dbus = {
    enable = true;
    packages = [pkgs.dconf];
  };

  # Create required directories and set permissions
  systemd.tmpfiles.rules = [
    # System dconf directories
    "d /run/dconf 0755 root root -"
    "d /etc/dconf/db 0755 root root -"
    "d /etc/dconf/profile 0755 root root -"

    # User directories with correct permissions
    "d /home/ryzengrind 0755 ryzengrind users -"
    "d /home/ryzengrind/.config 0755 ryzengrind users -"
    "d /home/ryzengrind/.local 0755 ryzengrind users -"
    "d /home/ryzengrind/.local/share 0755 ryzengrind users -"
    "d /home/ryzengrind/.cache 0755 ryzengrind users -"
    "d /home/ryzengrind/.cache/tmp 0755 ryzengrind users -"
  ];

  # Configure Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ryzengrind = {pkgs, ...}: {
      home = {
        username = "ryzengrind";
        homeDirectory = "/home/ryzengrind";
        stateVersion = "24.05";
      };

      # Disable dconf in Home Manager
      dconf.enable = false;

      # Basic XDG directories setup
      xdg = {
        enable = true;
      };

      # Basic GTK configuration
      gtk.enable = true;

      # Let Home Manager manage itself
      programs.home-manager.enable = true;

      # Starship configuration
      programs.starship = {
        enable = true;
        enableBashIntegration = true;
      };
    };
  };

  # User configuration
  users = {
    mutableUsers = true;
    users = {
      # Root user
      root = {
        shell = pkgs.bash;
        hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
      };
      # Regular user
      ryzengrind = {
        shell = pkgs.bash;
        isNormalUser = true;
        home = "/home/ryzengrind";
        createHome = true;
        group = "users";
        uid = 1000;
        extraGroups = ["audio" "networkmanager" "docker" "wheel"];
        hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
      };
    };
  };

  # Time and locale settings
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # WSL-specific system settings
  system.activationScripts.wslinit = {
    text = ''
      # Create required groups
      ${pkgs.shadow}/bin/groupadd -f users
      ${pkgs.shadow}/bin/groupadd -f wheel
      ${pkgs.shadow}/bin/groupadd -f audio
      ${pkgs.shadow}/bin/groupadd -f networkmanager
      ${pkgs.shadow}/bin/groupadd -f docker

      # Ensure user exists with correct shell and groups
      if ! id ryzengrind > /dev/null 2>&1; then
        ${pkgs.shadow}/bin/useradd -m -g users \
          -G wheel,audio,networkmanager,docker \
          -s ${pkgs.bash}/bin/bash \
          -d /home/ryzengrind \
          -u 1000 \
          ryzengrind
      else
        # Update existing user
        ${pkgs.shadow}/bin/usermod -g users \
          -G wheel,audio,networkmanager,docker \
          -s ${pkgs.bash}/bin/bash \
          -d /home/ryzengrind \
          ryzengrind
      fi

      # Set password if not set
      if ! ${pkgs.shadow}/bin/passwd -S ryzengrind > /dev/null 2>&1; then
        echo 'ryzengrind:$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.' | ${pkgs.shadow}/bin/chpasswd -e
      fi

      # Create and fix permissions for required directories
      mkdir -p /home/ryzengrind/{.config,.local,.local/share,.cache,.cache/tmp}
      chown -R ryzengrind:users /home/ryzengrind
      chmod 755 /home/ryzengrind
      chmod 700 /home/ryzengrind/.config
      chmod 700 /home/ryzengrind/.local
      chmod 700 /home/ryzengrind/.cache

      # Ensure shell is available
      if [ ! -f ${pkgs.bash}/bin/bash ]; then
        ln -sf ${pkgs.bash}/bin/bash /bin/bash
      fi
    '';
  };

  # Additional Surface Book 3 specific settings can be added here
}
