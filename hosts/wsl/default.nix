# WSL-specific base configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Import base configuration
    ../default.nix
    # Import WSL module from features
    ../../modules/nixos/features/wsl.nix
  ];

  # Enable WSL configuration
  core.features.wsl = {
    enable = true;
    gui.enable = true;
  };

  # Enable WSL configuration
  wsl = {
    enable = true;
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
      };
      interop = {
        appendWindowsPath = false;
      };
    };
    # Common WSL binaries
    extraBin = with pkgs; [
      {src = "${coreutils}/bin/cat";}
      {src = "${coreutils}/bin/whoami";}
      {src = "${su}/bin/groupadd";}
      {src = "${su}/bin/usermod";}
    ];
  };

  # WSL-specific packages that extend the base system packages
  environment.systemPackages = with pkgs;
    lib.mkMerge [
      # WSL-specific utilities
      [wslu wsl-open]
      # Development tools for WSL
      [nix-ld]
    ];

  # Enable nix-ld for better WSL compatibility
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc
      openssl
      curl
      glib
      util-linux
      glibc
    ];
  };

  # WSL-specific specialisation
  specialisation = {
    wsl = {
      inheritParentConfig = true;
      configuration = {_}: {
        system.nixos.tags = ["wsl"];
        # WSL-specific profile settings
        profiles = {
          dev = {
            enable = true;
            tools = {
              enable = true;
              editors = {
                cursor.enable = true;
                vscode.enable = true;
              };
            };
          };
        };
        # WSL-specific optimizations
        services.openssh.enable = lib.mkForce false;
        documentation = {
          enable = false;
          doc.enable = false;
          info.enable = false;
          man.enable = false;
        };
        nix.gc.dates = lib.mkForce "monthly";
      };
    };
  };

  # Common system configuration for WSL
  nixpkgs.config = lib.mkForce {
    allowUnfree = true;
    allowBroken = true;
  };

  # Basic nix settings for WSL
  nix.settings = lib.mkForce {
    experimental-features = ["nix-command" "flakes" "auto-allocate-uids"];
    auto-optimise-store = true;
    trusted-users = ["root" "@wheel"];
    max-jobs = "auto";
    cores = 0;
    keep-outputs = true;
    keep-derivations = true;
    system-features = [
      "big-parallel"
      "kvm"
      "nixos-test"
      "benchmark"
      "ca-derivations"
    ];
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  # Common services
  services.openssh = lib.mkForce {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # System state version
  system.stateVersion = lib.mkDefault "24.05";
}
