# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{ inputs
, outputs
, lib
, config
, pkgs
, ...
}: {
  imports = [
    inputs.nixos-wsl.nixosModules.wsl
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      system = "x86_64-linux"; # Explicitly set the system to resolve the error
    };
  };

  nix.registry = (lib.mapAttrs (_: flake: { inherit flake; })) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

  nix.nixPath = [ "/etc/nix/path" ];
  environment.etc =
    lib.mapAttrs'
      (name: value: {
        name = "nix/path/${name}";
        value.source = value.flake;
      })
      config.nix.registry;

  nix.settings = {
    experimental-features = "nix-command flakes repl-flake";
    auto-optimise-store = true;
  };

  networking.hostName = "daimyo00";
  networking.networkmanager.enable = true;

  boot.loader.systemd-boot.enable = false; # Disable for WSL
  boot.loader.efi.canTouchEfiVariables = false; # Disable for WSL

  time.timeZone = "America/Toronto";

  i18n.defaultLocale = "en_CA.UTF-8";

  services.xserver = {
    enable = false; # Typically disabled for WSL, adjust based on your setup
    desktopManager.gnome.enable = false; # Adjust based on your GUI needs
    displayManager.gdm.enable = false; # Adjust based on your GUI needs
  };

  services.printing.enable = true;
  services.flatpak.enable = false;
  services.zerotierone.enable = false;
  services.zerotierone.joinNetworks = [ "fada62b0158621fe" ];

  sound.enable = false; # Adjust based on your setup, typically disabled for WSL
  services.pipewire.enable = false; # Adjust based on your setup, typically disabled for WSL

  users.users = {
    ryzengrind = {
      hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq."; ##EDIT_ME##
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaDf9eWQpCOZfmuCwkc0kOH6ZerU7tprDlFTc+RHxCq Generated By Termius"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF9ky9rfRDFJSZQc+3cEpzBgvaKAF5cqAPSVBRxXRTkG RyzeNGrind@Shogun"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPL6GOQ1zpvnxJK0Mz+vUHgEd0f/sDB0q3pa38yHHEsC ronin@Ubuntu18S3"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJKxPRz8mlLOXoXnJdP211rBkflVCWth3KXgcz/qfw3 ronin@workerdroplet"
      ];
      extraGroups = [
        "wheel"
        "docker"
        "audio"
        "networkmanager"
      ];
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = true;
    };
  };

  services.teamviewer.enable = false; # Not applicable for WSL typically
  systemd.services."getty@tty1".enable = false; # Disable getty for WSL
  systemd.services."autovt@tty1".enable = false; # Disable autovt for WSL

  system.stateVersion = config.system.nixos.release; # Adjust according to your NixOS version
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false; # Adjust for WSL, typically reboots are not managed through NixOS in WSL
  system.autoUpgrade.channel = "https://channels.nixos.org/nixos-23.11";

  # Custom configurations specific to my NixOS-WSL setup
  wsl = {
    enable = true;
    defaultUser = "ryzengrind";
    docker-desktop.enable = false;
    nativeSystemd = true;
    startMenuLaunchers = true;
    wslConf = {
      automount = {
        enabled = true;
        options = "metadata,umask=22,fmask=11,uid=1000,gid=100";
        root = "/mnt";
      };
      network = {
        generateHosts = true;
        generateResolvConf = true;
        hostname = "daimyo00";
      };
      interop = {
        appendWindowsPath = false;
      };
    };
    extraBin = with pkgs; [
      { src = "${coreutils}/bin/mkdir"; }
      { src = "${coreutils}/bin/cat"; }
      { src = "${coreutils}/bin/whoami"; }
      { src = "${coreutils}/bin/ls"; }
      { src = "${busybox}/bin/addgroup"; }
      { src = "${su}/bin/groupadd"; }
      { src = "${su}/bin/usermod"; }
    ];
    tarball.configPath = ./configuration.nix;
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    wget
    neofetch
    nvtop
    _1password-gui-beta
    fish
    home-manager
    sd-switch
    dconf2nix
    screen
    nixops_unstable
    nixops-dns
    nixFlakes
  ];

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };

  users.groups.docker.members = [
    config.wsl.defaultUser
  ];

  programs.bash.loginShellInit = ''
    nixos-wsl-welcome &&
    if [ ${toString config.wsl.nativeSystemd} = "true" ]; then
      echo "Updating Nix channel..." &&
      sudo nix-channel --update &&
      echo "Channels updated successfully." &&
      echo "Upgrading NixOS system..." &&
      sudo nixos-rebuild switch --upgrade --show-trace &&
      echo "NixOS system upgrade completed."
    fi
  '';

  systemd.services.docker-desktop-proxy.script = lib.mkForce ''${config.wsl.wslConf.automount.root}/wsl/docker-desktop/docker-desktop-user-distro proxy --docker-desktop-root ${config.wsl.wslConf.automount.root}/wsl/docker-desktop "C:\Program Files\Docker\Docker\resources"'';

  systemd.services.nix-daemon-check = {
    script = ''
      if [ ${toString config.wsl.nativeSystemd} = "true" ]; then
        echo "Checking nix-daemon status..."
        systemctl is-active --quiet nix-daemon && echo "nix-daemon is active" || echo "nix-daemon is not active"
        echo "Attempting to start and enable nix-daemon..."
        systemctl start nix-daemon && systemctl enable nix-daemon
        if systemctl is-active --quiet nix-daemon; then
          echo "nix-daemon successfully restarted."
        else
          echo "Failed to restart nix-daemon."
        fi
      else
        echo "Systemd is not enabled. Skipping nix-daemon check."
      fi
    '';
  };
}
