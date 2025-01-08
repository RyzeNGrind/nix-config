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
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes repl-flake";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
  };

  # FIXME: Add the rest of your current configuration

  # TODO: Set your hostname
  networking.hostName = "shinobi";
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  # Enable networking
  networking.networkmanager.enable = true;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # TODO: This is just an example, be sure to use whatever bootloader you prefer
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

    # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";
  
  # Configure keymap in X11
  services.xserver = {
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
    layout = "us";
    xkbVariant = "";
    #xkbOptions = "ctrl:swapcaps";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.flatpak.enable = true;  
  services.zerotierone.enable = true;
  services.zerotierone.joinNetworks = [ "fada62b0158621fe" ]; # ZT NETWORK ID

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
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

  # TODO: Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    # FIXME: Replace with your username
    ryzengrind = {
      # TODO: You can set an initial password for your user.
      # If you do, you can skip setting a root password by passing '--no-root-passwd' to nixos-install.
      # Be sure to change it (using passwd) after rebooting!
      hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq."; ##EDIT_ME##
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
        "root"
        "wheel"
        "docker"
        "kmem"
        "tty"
        "messagebus"
        "disk"
        "audio"
        "floppy"
        "uucp"
        "lp"
        "cdrom"
        "tape"
        "video"
        "dialout"
        "utmp"
        "adm"
        "networkmanager"
        "systemd-journal"
        "keys"
        "users"
        "systemd-journal-gateway"
        "gdm"
        "systemd-network"
        "systemd-resolve"
        "systemd-timesync"
        "input"
        "nm-openvpn"
        "kvm"
        "render"
        "sgx"
        "shadow"
        "flatpak"
        "systemd-oom"
        "systemd-coredump"
        "rtkit"
        "polkituser"
        "nscd"
        "geoclue"
        "colord"
        "avahi"
        "nixbld"
        "nogroup"
      ];
    };
  };

  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  services.openssh = {
    enable = true;
    settings = {
      # Forbid root login through SSH.
      PermitRootLogin = "yes";
      # Use keys only. Remove if you want to SSH using password (not recommended)
      PasswordAuthentication = true;
    };
  };

  # disable teamviewer for nixos-wsl, 
  # TODO: replace with rustdesk for all non-headless systems (i.e except wsl and server systems)
  services.teamviewer.enable = false;
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = config.system.nixos.release;
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
  system.autoUpgrade.channel = "https://channels.nixos.org/nixos-23.11"; 
}