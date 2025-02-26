# Core system configuration module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.core;
  inherit (lib) mkIf mkMerge mkEnableOption mkOption types;
in {
  imports = [
    ./features.nix # Feature flag system
    ./network.nix # Network configuration
  ];

  options = {
    core = {
      enable = mkEnableOption "Core system configuration";
      system = {
        enable = mkEnableOption "System-wide configuration";
        kernel = {
          enable = mkEnableOption "Kernel configuration";
          packages = mkOption {
            type = types.attrs;
            default = pkgs.linuxPackages;
            description = "Linux kernel packages to use";
          };
          modules = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "List of kernel modules to load";
          };
        };
        shell = {
          enable = mkEnableOption "Shell configuration";
          fish = {
            enable = mkEnableOption "Fish shell";
            default = mkEnableOption "Use fish as default shell";
          };
          bash = {
            enable = mkEnableOption "Bash shell";
            default = mkEnableOption "Use bash as default shell";
          };
        };
        optimization = {
          enable = mkEnableOption "System optimization features";
          gc = {
            enable = mkEnableOption "Garbage collection";
            dates = mkOption {
              type = types.str;
              default = "weekly";
              description = "How often to run the garbage collector";
            };
            options = mkOption {
              type = types.str;
              default = "--delete-older-than 30d";
              description = "Options to pass to the garbage collector";
            };
          };
        };
        security = {
          enable = mkEnableOption "Security features";
          ssh = {
            enable = mkEnableOption "SSH configuration";
            permitRoot = mkEnableOption "Allow root login";
            passwordAuth = mkEnableOption "Allow password authentication";
          };
        };
        network = {
          enable = mkEnableOption "Network configuration";
          hostName = mkOption {
            type = types.str;
            default = "nixos";
            description = "Hostname of the system";
          };
          domain = mkOption {
            type = types.str;
            default = "";
            description = "Domain name of the system";
          };
        };
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Basic system configuration
      boot = mkIf cfg.system.kernel.enable {
        kernelPackages = cfg.system.kernel.packages;
        kernelModules = cfg.system.kernel.modules;
      };

      # Shell configuration
      programs = mkIf cfg.system.shell.enable {
        bash = mkIf cfg.system.shell.bash.enable {
          # Bash is enabled by default in NixOS, so we only configure it
          enableCompletion = true;
        };
        fish = mkIf cfg.system.shell.fish.enable {
          enable = true;
          vendor = {
            completions.enable = true;
            config.enable = true;
            functions.enable = true;
          };
        };
      };

      # Set default shell based on configuration with high priority
      users = mkIf cfg.system.shell.enable {
        defaultUserShell = lib.mkForce (
          if cfg.system.shell.fish.enable && cfg.system.shell.fish.default
          then pkgs.fish
          else if cfg.system.shell.bash.enable && cfg.system.shell.bash.default
          then pkgs.bash
          else pkgs.bash # Default to bash if no default is set
        );
        users.root.shell = lib.mkForce (
          if cfg.system.shell.fish.enable && cfg.system.shell.fish.default
          then pkgs.fish
          else if cfg.system.shell.bash.enable && cfg.system.shell.bash.default
          then pkgs.bash
          else pkgs.bash
        );
      };

      # Basic networking configuration
      networking = mkIf cfg.system.network.enable {
        inherit (cfg.system.network) hostName domain;
      };
    }
    {
      # Nix configuration
      nix = {
        settings = {
          experimental-features = [
            "nix-command"
            "flakes"
            "repl-flake"
          ];
          auto-optimise-store = true;
          trusted-users = ["root" "@wheel"];
        };

        # Garbage collection
        gc = lib.mkIf cfg.system.optimization.gc.enable {
          automatic = true;
          inherit (cfg.system.optimization.gc) dates options;
        };

        # Store optimization
        optimise = lib.mkIf cfg.system.optimization.enable {
          automatic = true;
          dates = ["weekly"];
        };
      };

      # Security configuration
      services.openssh = lib.mkIf cfg.system.security.ssh.enable {
        enable = true;
        settings = {
          PermitRootLogin =
            if cfg.system.security.ssh.permitRoot
            then "yes"
            else "no";
          PasswordAuthentication = cfg.system.security.ssh.passwordAuth;
        };
      };

      # Basic system packages
      environment.systemPackages = with pkgs; [
        # Core utilities
        coreutils
        curl
        wget
        git
      ];
    }
  ]);
}
