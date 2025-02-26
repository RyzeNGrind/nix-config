# Default NixOS configuration for all hosts
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    ../modules/core # Core system configuration
    ../modules/nixos/profiles # System profiles
  ];

  # Enable core system features
  core.system = {
    enable = true;
    optimization = {
      enable = true;
      gc.enable = true;
    };
    security = {
      enable = true;
      ssh = {
        enable = true;
        permitRoot = true;
        passwordAuth = true;
      };
    };
  };

  # SSH Server Configuration
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Cursor IDE Setup
  environment.etc."vscode-server/server-env-setup".source = ../scripts/utilities/bin/server-env-setup.sh;

  # Enable profiles based on system role
  profiles = {
    enable = true;
    dev.enable = lib.mkDefault true; # Enable development profile by default
  };

  # Common system configuration
  nixpkgs = {
    config = {
      inherit (config.nixpkgs.config) allowUnfree allowBroken;
    };
    overlays = [
      # Add any common overlays here
      (_: prev: {
        unstable = import inputs.nixpkgs-unstable {
          inherit (prev) system;
          inherit (pkgs.config.nixpkgs) config;
        };
      })
    ];
  };

  # Basic nix settings
  nix.settings = lib.mkDefault {
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
    auto-optimise-store = true;
    trusted-users = ["root" "@wheel"];
    max-jobs = "auto";
    cores = 0;
    keep-outputs = true;
    keep-derivations = true;
    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unstable.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://amdgpu-maintainers.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unstable.cachix.org-1:sK1OwYQYQwYzYJytAKfAbnPbBbQqATsqMk60OrE21V="
      "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5Xf4xT9XEl8hR638cjYJXGd5YpT4="
      "cuda-maintainers.cachix.org-1:LLh3HP1nZjS+Q+YVYbFZyfT5hkyYzB+X4wkB685BB0="
      "amdgpu-maintainers.cachix.org-1:ZiF5Z+Z7Jj6JQXj3PLwDx+QY8rZBuQgZ3NFZi0MahU5hbyzsIwqq.="
    ];
  };

  # Common user configuration
  users.users.ryzengrind = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    shell = pkgs.fish;
    hashedPassword = "$6$VOP1Yx5OUXwpOFaG$tVWf3Ai0.kzXpblhnatoeHHZb1xGKUuSEEQO79y1efrSyXR0sGmvFjo7oHbZBuQgZ3NFZi0MahU5hbyzsIwqq.";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaDf9eWQpCOZfmuCwkc0kOH6ZerU7tprDlFTc+RHxCq Generated By Termius"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF9ky9rfRDFJSZQc+3cEpzBgvaKAF5cqAPSVBRxXRTkG RyzeNGrind@Shogun"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPL6GOQ1zpvnxJK0Mz+vUHgEd0f/sDB0q3pa38yHHEsC ronin@Ubuntu18S3"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJKxPRz8mlLOXoXnJdP211rBkflVCWth3KXgcz/qfw3 ronin@workerdroplet"
    ];
  };

  # Common programs from upstream
  programs = {
    fish.enable = true;
    fish.interactiveShellInit = ''
      set -g fish_greeting
      fish_add_path ~/.local/bin
    '';
    git.enable = true;
    vim.defaultEditor = true;
  };

  # Network configuration
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [22 53 80 443];
    allowedUDPPorts = [53];
  };

  # Common specialisation base
  specialisation = {
    test = {
      inheritParentConfig = true;
      configuration = {pkgs, ...}: {
        system.nixos.tags = ["test"];

        # Test-specific settings
        environment.systemPackages = with pkgs; [
          nixos-test-runner
          nixos-generators
          qemu
          OVMF
        ];

        # Test-specific profile settings
        profiles = {
          dev.enable = true;
          dev.tools.enable = true;
        };

        # Test-specific nix settings
        nix.settings = {
          system-features = [
            "big-parallel"
            "kvm"
            "nixos-test"
            "benchmark"
            "ca-derivations"
          ];
        };
      };
    };
    srv = {
      inheritParentConfig = true;
      configuration = {pkgs, ...}: {
        system.nixos.tags = ["srv"];
        # Server-specific settings
        environment.systemPackages = with pkgs; [
          nginx
          certbot
          docker-compose
          docker
        ];
        # Server-specific profile settings
        profiles = {
          dev.enable = true;
          dev.tools.enable = true;
          srv.enable = true;
        };
        # Server-specific home-manager settings
        home-manager.users.ryzengrind = {
          profiles = {
            dev.enable = true;
            dev.tools.enable = true;
          };
        };
      };
    };
    bm = {
      inheritParentConfig = true;
      configuration = {_}: {
        system.nixos.tags = ["bm"];
        # Baremetal-specific settings
        hardware.enableAllFirmware = true;
        services.fwupd.enable = true;
        # Baremetal-specific profile settings
        profiles = {
          dev.enable = true;
          dev.tools.enable = true;
          desktop.enable = true;
          desktop.apps = {
            browsers.enable = true;
            communication.enable = true;
            media.enable = true;
            remote-desktop.enable = true;
          };
          security.enable = true;
          security.vpn.enable = true;
        };
        # Baremetal-specific home-manager settings
        home-manager.users.ryzengrind = {
          profiles = {
            dev = {
              enable = true;
              ide = "cursor";
              vscodeRemote.enable = true;
              tools.enable = true;
            };
            desktop = {
              enable = true;
              apps = {
                browsers.enable = true;
                communication.enable = true;
                media.enable = true;
                remote-desktop.enable = true;
              };
            };
            security = {
              enable = true;
              vpn.enable = true;
              tools.enable = true;
            };
          };
        };
      };
    };
  };

  # System state version
  system.stateVersion = lib.mkDefault "24.05";
}
