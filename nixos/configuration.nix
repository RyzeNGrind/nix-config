# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/nixos):
    # outputs.nixosModules.example

    # Or modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      allowBroken = true;  # Temporary workaround for TensorRT
      cudaSupport = true;
      allowUnfree = true;
      packageOverrides = pkgs: {
        cudaPackages = pkgs.cudaPackages_12_1;  # Use a stable CUDA version
      };
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = ["/etc/nix/path"];

    settings = {
      experimental-features = "nix-command flakes repl-flake";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
      # Connection settings
      http-connections = 10;
      max-jobs = 4;
      retry = 5;
      timeout = 300;
      # Add trusted users and substituters
      trusted-users = [ "root" "ryzengrind" "@wheel" ];
      substituters = [
        "https://cache.nixos.org"
        "https://cuda-maintainers.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };

  # FIXME: Add the rest of your current configuration

  # TODO: Set your hostname
  networking = {
    hostName = "shinobi";
    networkmanager.enable = true;
    # wireless.enable = true;  # Enables wireless support via wpa_supplicant
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot/efi";
      };
    };
  };

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";
  
  # Configure keymap in X11
  services = {
    xserver = {
      enable = true;
      #displayManager.gdm.wayland = false;
      #displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = false;
      };
      monitorSection = ''
        Option "Rotate" "right"
      '';
      xkb = {
        layout = "us";
        variant = "";
      };
      #xkbOptions = "ctrl:swapcaps";
      
      # NVIDIA-specific settings
      videoDrivers = [ "nvidia" ];
    };

    # Enable CUPS to print documents.
    printing.enable = true;
    flatpak.enable = true;  
    zerotierone = {
      enable = true;
      joinNetworks = [ "fada62b0158621fe" ]; # ZT NETWORK ID
    };

    # Enable sound with pipewire.
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      # If you want to use JACK applications, uncomment this
      #jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };

    # This setups a SSH server. Very important if you're setting up a headless system.
    # Feel free to remove if you don't need it.
    openssh = {
      enable = true;
      settings = {
        # Forbid root login through SSH.
        PermitRootLogin = "yes";
        # Use keys only. Remove if you want to SSH using password (not recommended)
        PasswordAuthentication = true;
      };
    };

    # Enable TeamViewer
    teamviewer.enable = true;
  };

  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    # FIXME: Replace with your username
    ryzengrind = {
      # TODO: You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      #initialPassword = "correcthorsebatterystaple";
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        # TODO: Add your SSH public key(s) here, if you plan on using SSH to connect
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaDf9eWQpCOZfmuCwkc0kOH6ZerU7tprDlFTc+RHxCq Generated By Termius"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF9ky9rfRDFJSZQc+3cEpzBgvaKAF5cqAPSVBRxXRTkG RyzeNGrind@Shogun"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPL6GOQ1zpvnxJK0Mz+vUHgEd0f/sDB0q3pa38yHHEsC ronin@Ubuntu18S3"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJKxPRz8mlLOXoXnJdP211rBkflVCWth3KXgcz/qfw3 ronin@workerdroplet"
        
      ];
      # TODO: Be sure to add any other groups you need (such as networkmanager, audio, docker, etc)
      extraGroups = [
        "root" "wheel" "docker" "kmem" "tty" "messagebus" "disk" "audio"
        "floppy" "uucp" "lp" "cdrom" "tape" "video" "dialout" "utmp" "adm"
        "networkmanager" "systemd-journal" "keys" "users" "systemd-journal-gateway"
        "gdm" "systemd-network" "systemd-resolve" "systemd-timesync" "input"
        "nm-openvpn" "kvm" "render" "sgx" "shadow" "flatpak" "systemd-oom"
        "systemd-coredump" "rtkit" "polkituser"
      ];
    };
  };

  # Disable TTY services
  systemd.services = {
    "getty@tty1".enable = false;
    "autovt@tty1".enable = false;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system = {
    stateVersion = "24.05";
    autoUpgrade = {
      enable = true;
      allowReboot = true;
      channel = "https://channels.nixos.org/nixos-24.05"; 
    };
  };

  # Hardware configuration
  hardware = {
    # Enable NVIDIA drivers only for non-WSL systems
    nvidia = lib.mkIf (!config.wsl.enable) {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      modesetting.enable = true;
      powerManagement = {
        enable = false;
        finegrained = false;
      };
      open = false;
      nvidiaSettings = true;
    };
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };
    pulseaudio.enable = false;  # Disable pulseaudio in favor of pipewire
  };
}

